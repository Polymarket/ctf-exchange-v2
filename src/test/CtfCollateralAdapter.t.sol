// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Deployer } from "src/test/dev/util/Deployer.sol";
import { TestHelper } from "src/test/dev/TestHelper.sol";
import { IConditionalTokens } from "src/adapters/interfaces/IConditionalTokens.sol";
import { CTHelpers } from "src/adapters/libraries/CTHelpers.sol";
import { CTFHelpers } from "src/adapters/libraries/CTFHelpers.sol";

import { Collateral, USDCe, CollateralSetup } from "src/test/dev/CollateralSetup.sol";

import { CollateralErrors } from "src/collateral/abstract/CollateralErrors.sol";
import { CtfCollateralAdapter } from "src/adapters/CtfCollateralAdapter.sol";

contract CtfCollateralAdapterTest is TestHelper {
    error Unauthorized();
    address admin = alice;
    address oracle = carly;

    Collateral collateral;
    USDCe usdce;

    IConditionalTokens conditionalTokens;
    CtfCollateralAdapter ctfCollateralAdapter;

    bytes32 questionId;
    bytes32 conditionId;

    uint256 amount = 100_000_000;

    function setUp() public {
        collateral = CollateralSetup._deploy(admin);
        usdce = collateral.usdce;

        conditionalTokens = IConditionalTokens(Deployer.deployConditionalTokens());

        ctfCollateralAdapter = new CtfCollateralAdapter(
            admin, admin, address(conditionalTokens), address(collateral.token), address(usdce)
        );

        vm.startPrank(admin);
        collateral.token.addWrapper(address(ctfCollateralAdapter));
        vm.stopPrank();

        questionId = "questionId";
        conditionalTokens.prepareCondition(oracle, questionId, 2);
        conditionId = CTHelpers.getConditionId(oracle, questionId, 2);
    }

    function test_CtfCollateralAdapter_splitPosition() public {
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.onramp), amount);
        collateral.onramp.wrap(address(usdce), alice, amount);

        assertEq(usdce.balanceOf(alice), 0);
        assertEq(collateral.token.balanceOf(alice), amount);

        collateral.token.approve(address(ctfCollateralAdapter), amount);
        ctfCollateralAdapter.splitPosition(address(0), bytes32(0), conditionId, CTFHelpers.partition(), amount);
        vm.stopPrank();

        uint256[] memory positionIds = CTFHelpers.positionIds(address(usdce), conditionId);
        assertEq(conditionalTokens.balanceOf(alice, positionIds[0]), amount);
        assertEq(conditionalTokens.balanceOf(alice, positionIds[1]), amount);
    }

    function test_CtfCollateralAdapter_mergePositions() public {
        test_CtfCollateralAdapter_splitPosition();

        uint256[] memory positionIds = CTFHelpers.positionIds(address(usdce), conditionId);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;
        vm.prank(alice);
        conditionalTokens.safeBatchTransferFrom(alice, brian, positionIds, amounts, "");

        vm.startPrank(brian);
        conditionalTokens.setApprovalForAll(address(ctfCollateralAdapter), true);
        ctfCollateralAdapter.mergePositions(address(0), bytes32(0), conditionId, CTFHelpers.partition(), amount);
        vm.stopPrank();

        assertEq(collateral.token.balanceOf(brian), amount);
    }

    function test_CtfCollateralAdapter_redeemPositions(bool _outcome) public {
        test_CtfCollateralAdapter_splitPosition();

        uint256[] memory positionIds = CTFHelpers.positionIds(address(usdce), conditionId);

        uint256[] memory payouts = new uint256[](2);
        payouts[0] = _outcome ? 1 : 0;
        payouts[1] = _outcome ? 0 : 1;

        vm.prank(oracle);
        conditionalTokens.reportPayouts(questionId, payouts);

        vm.startPrank(alice);
        conditionalTokens.setApprovalForAll(address(ctfCollateralAdapter), true);
        conditionalTokens.safeTransferFrom(alice, brian, positionIds[1], amount, "");
        ctfCollateralAdapter.redeemPositions(address(0), bytes32(0), conditionId, CTFHelpers.partition());
        vm.stopPrank();

        vm.startPrank(brian);
        conditionalTokens.setApprovalForAll(address(ctfCollateralAdapter), true);
        ctfCollateralAdapter.redeemPositions(address(0), bytes32(0), conditionId, CTFHelpers.partition());
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

    function test_revert_CtfCollateralAdapter_splitPosition_paused() public {
        vm.prank(admin);
        ctfCollateralAdapter.pause(address(usdce));

        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.onramp), amount);
        collateral.onramp.wrap(address(usdce), alice, amount);
        collateral.token.approve(address(ctfCollateralAdapter), amount);

        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        ctfCollateralAdapter.splitPosition(address(0), bytes32(0), conditionId, CTFHelpers.partition(), amount);
        vm.stopPrank();
    }

    function test_revert_CtfCollateralAdapter_mergePositions_paused() public {
        test_CtfCollateralAdapter_splitPosition();

        vm.prank(admin);
        ctfCollateralAdapter.pause(address(usdce));

        uint256[] memory positionIds = CTFHelpers.positionIds(address(usdce), conditionId);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        amounts[1] = amount;
        vm.prank(alice);
        conditionalTokens.safeBatchTransferFrom(alice, brian, positionIds, amounts, "");

        vm.startPrank(brian);
        conditionalTokens.setApprovalForAll(address(ctfCollateralAdapter), true);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        ctfCollateralAdapter.mergePositions(address(0), bytes32(0), conditionId, CTFHelpers.partition(), amount);
        vm.stopPrank();
    }

    function test_revert_CtfCollateralAdapter_redeemPositions_paused() public {
        test_CtfCollateralAdapter_splitPosition();

        uint256[] memory payouts = new uint256[](2);
        payouts[0] = 1;
        payouts[1] = 0;

        vm.prank(oracle);
        conditionalTokens.reportPayouts(questionId, payouts);

        vm.prank(admin);
        ctfCollateralAdapter.pause(address(usdce));

        vm.startPrank(alice);
        conditionalTokens.setApprovalForAll(address(ctfCollateralAdapter), true);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        ctfCollateralAdapter.redeemPositions(address(0), bytes32(0), conditionId, CTFHelpers.partition());
        vm.stopPrank();
    }

    function test_CtfCollateralAdapter_unpause() public {
        vm.prank(admin);
        ctfCollateralAdapter.pause(address(usdce));

        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.onramp), amount);
        collateral.onramp.wrap(address(usdce), alice, amount);
        collateral.token.approve(address(ctfCollateralAdapter), amount);

        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        ctfCollateralAdapter.splitPosition(address(0), bytes32(0), conditionId, CTFHelpers.partition(), amount);
        vm.stopPrank();

        vm.prank(admin);
        ctfCollateralAdapter.unpause(address(usdce));

        vm.prank(alice);
        ctfCollateralAdapter.splitPosition(address(0), bytes32(0), conditionId, CTFHelpers.partition(), amount);

        uint256[] memory positionIds = CTFHelpers.positionIds(address(usdce), conditionId);
        assertEq(conditionalTokens.balanceOf(alice, positionIds[0]), amount);
        assertEq(conditionalTokens.balanceOf(alice, positionIds[1]), amount);
    }

    function test_revert_CtfCollateralAdapter_pause_unauthorized() public {
        vm.prank(brian);
        vm.expectRevert(Unauthorized.selector);
        ctfCollateralAdapter.pause(address(usdce));
    }
}
