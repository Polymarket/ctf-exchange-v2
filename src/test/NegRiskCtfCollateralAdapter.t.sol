// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Collateral, USDCe, CollateralSetup } from "src/test/dev/CollateralSetup.sol";
import { Deployer } from "src/test/dev/util/Deployer.sol";
import { TestHelper } from "src/test/dev/TestHelper.sol";
import { CTFHelpers } from "src/adapters/libraries/CTFHelpers.sol";
// TODO: NegRiskAdapterSetUp needs to be created - requires NegRiskAdapter artifact
import { NegRiskAdapterSetUp } from "src/test/dev/NegRiskAdapterSetUp.sol";
import { IConditionalTokens } from "src/adapters/interfaces/IConditionalTokens.sol";
import { INegRiskAdapter } from "src/adapters/interfaces/INegRiskAdapter.sol";

import { CollateralErrors } from "src/collateral/abstract/CollateralErrors.sol";
import { NegRiskCtfCollateralAdapter } from "src/adapters/NegRiskCtfCollateralAdapter.sol";

contract NegRiskCtfCollateralAdapterTest is TestHelper {
    error Unauthorized();
    address admin = alice;
    address owner = alice;
    address oracle = carly;

    Collateral collateral;
    USDCe usdce;

    INegRiskAdapter negRiskAdapter;
    IConditionalTokens conditionalTokens;

    NegRiskCtfCollateralAdapter negRiskCtfCollateralAdapter;

    bytes32[] questionIds;
    bytes32[] conditionIds;

    address wrappedCollateral;
    bytes32 negRiskMarketId;

    uint256 amount = 100_000_000;

    function setUp() public {
        collateral = CollateralSetup._deploy(admin);
        usdce = collateral.usdce;

        conditionalTokens = IConditionalTokens(Deployer.deployConditionalTokens());

        (negRiskAdapter, conditionalTokens, wrappedCollateral) = NegRiskAdapterSetUp.deploy(owner, address(usdce));

        negRiskCtfCollateralAdapter = new NegRiskCtfCollateralAdapter(
            admin, admin, address(conditionalTokens), address(collateral.token), address(usdce), address(negRiskAdapter)
        );

        vm.startPrank(admin);
        collateral.token.addWrapper(address(negRiskCtfCollateralAdapter));
        vm.stopPrank();
    }

    function _before(uint256 _questionCount) internal {
        bytes memory data = new bytes(0);

        // prepare market
        vm.prank(oracle);
        negRiskMarketId = negRiskAdapter.prepareMarket(0, data);

        uint8 i = 0;

        // prepare questions
        while (i < _questionCount) {
            vm.prank(oracle);
            questionIds.push(negRiskAdapter.prepareQuestion(negRiskMarketId, data));
            conditionIds.push(negRiskAdapter.getConditionId(questionIds[i]));

            ++i;
        }

        assertEq(negRiskAdapter.getQuestionCount(negRiskMarketId), _questionCount);
    }

    function test_NegRiskCtfCollateralAdapter_splitPosition() public {
        _before(4);

        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.onramp), amount);

        collateral.onramp.wrap(address(usdce), alice, amount);

        assertEq(usdce.balanceOf(alice), 0);
        assertEq(collateral.token.balanceOf(alice), amount);

        collateral.token.approve(address(negRiskCtfCollateralAdapter), amount);
        negRiskCtfCollateralAdapter.splitPosition(
            address(0), bytes32(0), conditionIds[0], CTFHelpers.partition(), amount
        );
        vm.stopPrank();

        uint256[] memory positionIds = CTFHelpers.positionIds(address(wrappedCollateral), conditionIds[0]);
        assertEq(conditionalTokens.balanceOf(alice, positionIds[0]), amount);
        assertEq(conditionalTokens.balanceOf(alice, positionIds[1]), amount);
    }

    function test_NegRiskCtfCollateralAdapter_mergePositions() public {
        test_NegRiskCtfCollateralAdapter_splitPosition();

        uint256[] memory positionIds = CTFHelpers.positionIds(address(wrappedCollateral), conditionIds[0]);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;

        vm.prank(alice);
        conditionalTokens.safeBatchTransferFrom(alice, brian, positionIds, amounts, "");

        vm.startPrank(brian);
        conditionalTokens.setApprovalForAll(address(negRiskCtfCollateralAdapter), true);
        negRiskCtfCollateralAdapter.mergePositions(
            address(0), bytes32(0), conditionIds[0], CTFHelpers.partition(), amount
        );
        vm.stopPrank();

        assertEq(collateral.token.balanceOf(brian), amount);
    }

    // --- helpers for convertPositions tests ---

    function _splitAllQuestions(address _user, uint256 _amount) internal {
        usdce.mint(_user, _amount * questionIds.length);

        vm.startPrank(_user);
        usdce.approve(address(collateral.onramp), _amount * questionIds.length);
        collateral.onramp.wrap(address(usdce), _user, _amount * questionIds.length);

        collateral.token.approve(address(negRiskCtfCollateralAdapter), _amount * questionIds.length);
        for (uint256 i; i < questionIds.length; ++i) {
            negRiskCtfCollateralAdapter.splitPosition(
                address(0), bytes32(0), conditionIds[i], CTFHelpers.partition(), _amount
            );
        }
        conditionalTokens.setApprovalForAll(address(negRiskCtfCollateralAdapter), true);
        vm.stopPrank();
    }

    function test_NegRiskCtfCollateralAdapter_convertPositions_oneNoToYes() public {
        _before(4);
        _splitAllQuestions(alice, amount);

        vm.prank(alice);
        negRiskCtfCollateralAdapter.convertPositions(negRiskMarketId, 1, amount); // indexSet = 0b0001

        // YES balances for questions 1,2,3: amount (from split) + amount (from convert) = 2*amount
        for (uint256 i = 1; i < 4; ++i) {
            bytes32 qId = bytes32(uint256(negRiskMarketId) | i);
            uint256 yesPos = negRiskAdapter.getPositionId(qId, true);
            assertEq(conditionalTokens.balanceOf(alice, yesPos), 2 * amount);
        }

        // NO token for question 0 should be gone (spent in convert)
        bytes32 q0 = bytes32(uint256(negRiskMarketId) | 0);
        uint256 noPos0 = negRiskAdapter.getPositionId(q0, false);
        assertEq(conditionalTokens.balanceOf(alice, noPos0), 0);

        // No collateral returned (noCount - 1 = 0)
        assertEq(collateral.token.balanceOf(alice), 0);

        // Adapter residual checks
        assertEq(usdce.balanceOf(address(negRiskCtfCollateralAdapter)), 0);
    }

    function test_NegRiskCtfCollateralAdapter_convertPositions_twoNoToYes() public {
        _before(4);
        _splitAllQuestions(alice, amount);

        vm.prank(alice);
        negRiskCtfCollateralAdapter.convertPositions(negRiskMarketId, 3, amount); // indexSet = 0b0011

        // YES balances for questions 2,3: amount (from split) + amount (from convert) = 2*amount
        for (uint256 i = 2; i < 4; ++i) {
            bytes32 qId = bytes32(uint256(negRiskMarketId) | i);
            uint256 yesPos = negRiskAdapter.getPositionId(qId, true);
            assertEq(conditionalTokens.balanceOf(alice, yesPos), 2 * amount);
        }

        // NO tokens for questions 0,1 should be gone
        for (uint256 i = 0; i < 2; ++i) {
            bytes32 qId = bytes32(uint256(negRiskMarketId) | i);
            uint256 noPos = negRiskAdapter.getPositionId(qId, false);
            assertEq(conditionalTokens.balanceOf(alice, noPos), 0);
        }

        // Collateral = (2-1) * amount = amount, wrapped as CollateralToken
        assertEq(collateral.token.balanceOf(alice), amount);
        assertEq(usdce.balanceOf(alice), 0);
        assertEq(usdce.balanceOf(address(negRiskCtfCollateralAdapter)), 0);
    }

    function test_NegRiskCtfCollateralAdapter_convertPositions_threeNoToYes() public {
        _before(4);
        _splitAllQuestions(alice, amount);

        vm.prank(alice);
        negRiskCtfCollateralAdapter.convertPositions(negRiskMarketId, 7, amount); // indexSet = 0b0111

        // YES balance for question 3: amount (from split) + amount (from convert) = 2*amount
        bytes32 qId = bytes32(uint256(negRiskMarketId) | 3);
        uint256 yesPos = negRiskAdapter.getPositionId(qId, true);
        assertEq(conditionalTokens.balanceOf(alice, yesPos), 2 * amount);

        // NO tokens for questions 0,1,2 should be gone
        for (uint256 i = 0; i < 3; ++i) {
            bytes32 qi = bytes32(uint256(negRiskMarketId) | i);
            uint256 noPos = negRiskAdapter.getPositionId(qi, false);
            assertEq(conditionalTokens.balanceOf(alice, noPos), 0);
        }

        // Collateral = (3-1) * amount = 2 * amount
        assertEq(collateral.token.balanceOf(alice), 2 * amount);
        assertEq(usdce.balanceOf(address(negRiskCtfCollateralAdapter)), 0);
    }

    function test_NegRiskCtfCollateralAdapter_convertPositions_withFees() public {
        // Create market with 200 bips (2%) fee
        bytes memory data = new bytes(0);
        vm.prank(oracle);
        negRiskMarketId = negRiskAdapter.prepareMarket(200, data);

        for (uint8 i = 0; i < 4; ++i) {
            vm.prank(oracle);
            questionIds.push(negRiskAdapter.prepareQuestion(negRiskMarketId, data));
            conditionIds.push(negRiskAdapter.getConditionId(questionIds[i]));
        }

        _splitAllQuestions(alice, amount);

        vm.prank(alice);
        negRiskCtfCollateralAdapter.convertPositions(negRiskMarketId, 3, amount); // indexSet = 0b0011

        uint256 fee = amount * 200 / 10_000;
        uint256 amountOut = amount - fee;

        // YES balances for questions 2,3: amount (from split, no fee) + amountOut (from convert, after fee)
        for (uint256 i = 2; i < 4; ++i) {
            bytes32 qId = bytes32(uint256(negRiskMarketId) | i);
            uint256 yesPos = negRiskAdapter.getPositionId(qId, true);
            assertEq(conditionalTokens.balanceOf(alice, yesPos), amount + amountOut);
        }

        // Collateral = (2-1) * amountOut
        assertEq(collateral.token.balanceOf(alice), amountOut);
        assertEq(usdce.balanceOf(address(negRiskCtfCollateralAdapter)), 0);
    }

    function test_NegRiskCtfCollateralAdapter_convertPositions_zeroAmount() public {
        _before(4);
        _splitAllQuestions(alice, amount);

        uint256 collateralBefore = collateral.token.balanceOf(alice);

        vm.prank(alice);
        negRiskCtfCollateralAdapter.convertPositions(negRiskMarketId, 3, 0);

        assertEq(collateral.token.balanceOf(alice), collateralBefore);
        assertEq(usdce.balanceOf(address(negRiskCtfCollateralAdapter)), 0);
    }

    function test_NegRiskCtfCollateralAdapter_redeemPositions(bool _outcome) public {
        test_NegRiskCtfCollateralAdapter_splitPosition();

        uint256[] memory positionIds = CTFHelpers.positionIds(address(wrappedCollateral), conditionIds[0]);

        vm.prank(oracle);
        negRiskAdapter.reportOutcome(questionIds[0], _outcome);

        vm.startPrank(alice);
        conditionalTokens.setApprovalForAll(address(negRiskCtfCollateralAdapter), true);
        conditionalTokens.safeTransferFrom(alice, brian, positionIds[1], amount, "");
        negRiskCtfCollateralAdapter.redeemPositions(address(0), bytes32(0), conditionIds[0], CTFHelpers.partition());
        vm.stopPrank();

        vm.startPrank(brian);
        conditionalTokens.setApprovalForAll(address(negRiskCtfCollateralAdapter), true);
        negRiskCtfCollateralAdapter.redeemPositions(address(0), bytes32(0), conditionIds[0], CTFHelpers.partition());
        vm.stopPrank();

        assertEq(collateral.token.balanceOf(_outcome ? alice : brian), amount);
        assertEq(collateral.token.balanceOf(_outcome ? brian : alice), 0);

        assertEq(conditionalTokens.balanceOf(alice, positionIds[0]), 0);
        assertEq(conditionalTokens.balanceOf(alice, positionIds[1]), 0);
        assertEq(conditionalTokens.balanceOf(brian, positionIds[0]), 0);
        assertEq(conditionalTokens.balanceOf(brian, positionIds[1]), 0);
    }

    /*--------------------------------------------------------------
                            PAUSE TESTS
    --------------------------------------------------------------*/

    function test_revert_NegRiskCtfCollateralAdapter_splitPosition_paused() public {
        _before(4);

        vm.prank(admin);
        negRiskCtfCollateralAdapter.pause(address(usdce));

        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.onramp), amount);
        collateral.onramp.wrap(address(usdce), alice, amount);
        collateral.token.approve(address(negRiskCtfCollateralAdapter), amount);

        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        negRiskCtfCollateralAdapter.splitPosition(
            address(0), bytes32(0), conditionIds[0], CTFHelpers.partition(), amount
        );
        vm.stopPrank();
    }

    function test_revert_NegRiskCtfCollateralAdapter_mergePositions_paused() public {
        test_NegRiskCtfCollateralAdapter_splitPosition();

        vm.prank(admin);
        negRiskCtfCollateralAdapter.pause(address(usdce));

        uint256[] memory positionIds = CTFHelpers.positionIds(address(wrappedCollateral), conditionIds[0]);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;
        vm.prank(alice);
        conditionalTokens.safeBatchTransferFrom(alice, brian, positionIds, amounts, "");

        vm.startPrank(brian);
        conditionalTokens.setApprovalForAll(address(negRiskCtfCollateralAdapter), true);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        negRiskCtfCollateralAdapter.mergePositions(
            address(0), bytes32(0), conditionIds[0], CTFHelpers.partition(), amount
        );
        vm.stopPrank();
    }

    function test_revert_NegRiskCtfCollateralAdapter_redeemPositions_paused() public {
        test_NegRiskCtfCollateralAdapter_splitPosition();

        vm.prank(oracle);
        negRiskAdapter.reportOutcome(questionIds[0], true);

        vm.prank(admin);
        negRiskCtfCollateralAdapter.pause(address(usdce));

        vm.startPrank(alice);
        conditionalTokens.setApprovalForAll(address(negRiskCtfCollateralAdapter), true);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        negRiskCtfCollateralAdapter.redeemPositions(address(0), bytes32(0), conditionIds[0], CTFHelpers.partition());
        vm.stopPrank();
    }

    function test_revert_NegRiskCtfCollateralAdapter_convertPositions_paused() public {
        _before(4);
        _splitAllQuestions(alice, amount);

        vm.prank(admin);
        negRiskCtfCollateralAdapter.pause(address(usdce));

        vm.prank(alice);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        negRiskCtfCollateralAdapter.convertPositions(negRiskMarketId, 1, amount);
    }
}
