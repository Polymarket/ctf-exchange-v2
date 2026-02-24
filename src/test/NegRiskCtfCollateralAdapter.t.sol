// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Collateral, USDCe, CollateralSetup } from "src/test/dev/CollateralSetup.sol";
import { Deployer } from "src/test/dev/util/Deployer.sol";
import { TestHelper } from "src/test/dev/TestHelper.sol";
import { CTFHelpers } from "src/adapters/libraries/CTFHelpers.sol";
// TODO: NegRiskAdapterSetUp needs to be created - requires NegRiskAdapter artifact
import { NegRiskAdapterSetUp } from "src/test/dev/NegRiskAdapterSetUp.sol";
import { IConditionalTokens } from "src/adapters/interfaces/IConditionalTokens.sol";
import { INegRiskAdapter } from "src/adapters/interfaces/INegRiskAdapter.sol";

import { NegRiskCtfCollateralAdapter } from "src/adapters/NegRiskCtfCollateralAdapter.sol";

contract NegRiskCtfCollateralAdapterTest is TestHelper {
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
            address(conditionalTokens), address(collateral.token), address(usdce), address(negRiskAdapter)
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
}
