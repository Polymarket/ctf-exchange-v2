// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { ERC1155 } from "lib/solady/src/tokens/ERC1155.sol";

import { ToggleableERC1271Mock } from "./dev/mocks/ToggleableERC1271Mock.sol";
import { Order, Side, SignatureType } from "src/exchange/libraries/Structs.sol";

import { BaseExchangeTest } from "./BaseExchangeTest.sol";

contract PreapprovedTest is BaseExchangeTest {
    ToggleableERC1271Mock public toggleWallet;

    function setUp() public override {
        super.setUp();
        toggleWallet = new ToggleableERC1271Mock(carla);
    }

    // ──────────────────────────────────────────────────
    // Test 1: Invalidated preapproval reverts on match
    // ──────────────────────────────────────────────────

    function test_matchOrders_invalidatedPreapproval_reverts() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        bytes32 makerOrderHash = exchange.hashOrder(makerOrder);

        // Preapprove the maker order
        vm.expectEmit(true, false, false, false);
        emit OrderPreapproved(makerOrderHash);
        vm.prank(admin);
        exchange.preapproveOrder(makerOrder);

        // Invalidate the ECDSA signature so only preapproval can authorize.
        _invalidateSignature(makerOrder);

        // Now invalidate the preapproval
        vm.expectEmit(true, false, false, false);
        emit OrderPreapprovalInvalidated(makerOrderHash);
        vm.prank(admin);
        exchange.invalidatePreapprovedOrder(makerOrderHash);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        // Should revert: signature is invalid AND preapproval has been invalidated
        vm.expectRevert(InvalidSignature.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts);
    }

    // ──────────────────────────────────────────────────
    // Test 2: preapproveOrder reverts on invalid signature
    // ──────────────────────────────────────────────────

    function test_preapproveOrder_revert_invalidSignature() public {
        Order memory order = _createOrder(bob, yes, 50_000_000, 100_000_000, Side.BUY);
        // Sign with the wrong key (carla signs bob's order)
        order.signature = _signMessage(carlaPK, exchange.hashOrder(order));

        vm.expectRevert(InvalidSignature.selector);
        vm.prank(admin);
        exchange.preapproveOrder(order);
    }

    // ──────────────────────────────────────────────────
    // Test 2b: preapproveOrder reverts when called by non-operator
    // ──────────────────────────────────────────────────

    function test_preapproveOrder_revert_NotOperator() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // Use an address that is not an operator
        address nonOperator = address(0xBEEF);

        vm.expectRevert(NotOperator.selector);
        vm.prank(nonOperator);
        exchange.preapproveOrder(order);
    }

    // ──────────────────────────────────────────────────
    // Test 3: Preapproved maker order matches (complementary)
    // ──────────────────────────────────────────────────

    function test_matchOrders_preapprovedMaker_complementary() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        // Taker: YES BUY
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        // Maker: YES SELL (preapproved)
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        // Preapprove the maker order, then invalidate its signature
        // so only preapproval can authorize the match
        vm.prank(admin);
        exchange.preapproveOrder(makerOrder);
        _invalidateSignature(makerOrder);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts);

        vm.pauseGasMetering();
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 50_000_000);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).filled);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(makerOrder)).filled);
    }

    // ──────────────────────────────────────────────────
    // Test 4: Preapproved taker order matches (complementary)
    // ──────────────────────────────────────────────────

    function test_matchOrders_preapprovedTaker_complementary() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        // Taker: YES BUY
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        // Maker: YES SELL
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        // Preapprove the taker order, then invalidate its signature
        // so only preapproval can authorize the match
        vm.prank(admin);
        exchange.preapproveOrder(takerOrder);
        _invalidateSignature(takerOrder);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts);

        vm.pauseGasMetering();
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 50_000_000);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).filled);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(makerOrder)).filled);
    }

    // ──────────────────────────────────────────────────
    // Test 5: Preapproved order respects filled status
    // ──────────────────────────────────────────────────

    function test_matchOrders_preapproved_respectsFilledStatus() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        // Preapprove both, then invalidate signatures
        // so only preapproval can authorize the match
        vm.startPrank(admin);
        exchange.preapproveOrder(takerOrder);
        exchange.preapproveOrder(makerOrder);
        vm.stopPrank();
        _invalidateSignature(takerOrder);
        _invalidateSignature(makerOrder);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // First match: fill completely (authorized by preapproval)
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts);

        vm.resumeGasMetering();

        // Second match: should revert because taker order is already filled
        vm.expectRevert(OrderAlreadyFilled.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts);
    }

    // ──────────────────────────────────────────────────
    // Test 6: Preapproved order respects user pause
    // ──────────────────────────────────────────────────

    function test_matchOrders_preapproved_respectsUserPause() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        // Preapprove the taker order, then invalidate its signature
        // so only preapproval can authorize the match
        vm.prank(admin);
        exchange.preapproveOrder(takerOrder);
        _invalidateSignature(takerOrder);

        // Bob pauses himself
        vm.prank(bob);
        exchange.pauseUser();

        // Advance past pause interval (100 blocks)
        vm.roll(block.number + 101);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        // Should revert because bob is paused, even though order is preapproved
        vm.expectRevert(UserIsPaused.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts);
    }

    // ──────────────────────────────────────────────────
    // Test 7: Preapproved order partial fill
    // ──────────────────────────────────────────────────

    function test_matchOrders_preapproved_partialFill() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 50_000_000);

        // Bob wants to buy 100 YES for 50 USDC (full order)
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        // Carla sells only 50 YES for 25 USDC (half fill)
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 50_000_000, 25_000_000, Side.SELL);

        // Preapprove the taker order, then invalidate its signature
        // so only preapproval can authorize the match across both partial fills
        vm.prank(admin);
        exchange.preapproveOrder(takerOrder);
        _invalidateSignature(takerOrder);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // Fill half of the taker order (25 USDC worth)
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 25_000_000, fillAmounts, 0, makerFeeAmounts);

        // Taker order should NOT be fully filled
        assertFalse(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).filled);
        assertEq(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).remaining, 25_000_000);

        // Now fill the rest with a new maker
        uint256 davePK = 0xDA7E;
        address dave = vm.addr(davePK);
        vm.label(dave, "dave");
        vm.prank(admin);
        exchange.addOperator(dave);
        dealOutcomeTokensAndApprove(dave, address(exchange), yes, 50_000_000);

        Order memory makerOrder2 = _createOrder(dave, yes, 50_000_000, 25_000_000, Side.SELL);
        makerOrder2.salt = 2;
        makerOrder2.signature = _signMessage(davePK, exchange.hashOrder(makerOrder2));

        makerOrders[0] = makerOrder2;
        fillAmounts[0] = 50_000_000;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 25_000_000, fillAmounts, 0, makerFeeAmounts);

        vm.pauseGasMetering();
        // Taker order should now be fully filled
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).filled);
        // Bob spent 50 USDC, received 100 YES
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
    }

    // ──────────────────────────────────────────────────
    // Test 8: Invalid signature without preapproval reverts (negative control)
    // ──────────────────────────────────────────────────

    function test_matchOrders_invalidSignature_notPreapproved_reverts() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        // Taker: YES BUY — valid sig, but NOT preapproved, then invalidated
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        _invalidateSignature(takerOrder);

        // Maker: YES SELL — validly signed
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        // Should revert: invalid signature and no preapproval
        vm.expectRevert(InvalidSignature.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts);
    }

    // ──────────────────────────────────────────────────
    // Test 9: ERC1271 preapproved order works after signer invalidation
    // ──────────────────────────────────────────────────

    function test_matchOrders_preapproved1271_signerInvalidated() public {
        vm.pauseGasMetering();

        // Setup: fund the toggleWallet with enough for two orders
        dealUsdcAndApprove(address(toggleWallet), address(exchange), 100_000_000);

        // Create two POLY_1271 orders from the same wallet, different salts
        Order memory preapprovedOrder =
            _createAndSign1271Order(carlaPK, address(toggleWallet), yes, 50_000_000, 100_000_000, Side.BUY);

        Order memory notPreapprovedOrder = _createOrder(address(toggleWallet), yes, 50_000_000, 100_000_000, Side.BUY);
        notPreapprovedOrder.salt = 2;
        notPreapprovedOrder.signatureType = SignatureType.POLY_1271;
        notPreapprovedOrder.signature = _signMessage(carlaPK, exchange.hashOrder(notPreapprovedOrder));

        // Preapprove only the first order while the wallet is active
        vm.prank(admin);
        exchange.preapproveOrder(preapprovedOrder);

        // Disable the wallet's signature validation (simulates session signer deauthorization)
        toggleWallet.disable();

        // Verify: non-preapproved order from disabled wallet FAILS to match
        {
            dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
            Order memory makerForFail = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);

            Order[] memory makerOrders = new Order[](1);
            makerOrders[0] = makerForFail;
            uint256[] memory fillAmounts = new uint256[](1);
            fillAmounts[0] = 100_000_000;
            uint256[] memory makerFeeAmounts = new uint256[](1);
            makerFeeAmounts[0] = 0;

            vm.expectRevert(InvalidSignature.selector);
            vm.prank(admin);
            exchange.matchOrders(
                conditionId, notPreapprovedOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts
            );
        }

        // Verify: preapproved order from disabled wallet SUCCEEDS
        {
            dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);
            Order memory makerForSuccess = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

            Order[] memory makerOrders = new Order[](1);
            makerOrders[0] = makerForSuccess;
            uint256[] memory fillAmounts = new uint256[](1);
            fillAmounts[0] = 100_000_000;
            uint256[] memory makerFeeAmounts = new uint256[](1);
            makerFeeAmounts[0] = 0;

            vm.resumeGasMetering();

            vm.prank(admin);
            exchange.matchOrders(
                conditionId, preapprovedOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts
            );
        }

        vm.pauseGasMetering();
        // Wallet spent 50 USDC on the preapproved order, has 50 left
        assertCollateralBalance(address(toggleWallet), 50_000_000);
        assertCTFBalance(address(toggleWallet), yes, 100_000_000);
        // Preapproved order filled, non-preapproved order not filled
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(preapprovedOrder)).filled);
        assertFalse(exchange.getOrderStatus(exchange.hashOrder(notPreapprovedOrder)).filled);
    }
}
