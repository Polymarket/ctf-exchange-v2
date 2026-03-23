// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import {
    Order,
    Side,
    MatchType,
    OrderStatus,
    SignatureType
} from "@ctf-exchange-v2/src/exchange/libraries/Structs.sol";

contract CTFExchangeTest is BaseExchangeTest {
    event ProxyFactoryUpdated(address indexed oldProxyFactory, address indexed newProxyFactory);
    event SafeFactoryUpdated(address indexed oldSafeFactory, address indexed newSafeFactory);

    function test_CTFExchange_setup() public view {
        assertTrue(exchange.isAdmin(admin));
        assertTrue(exchange.isOperator(admin));
        assertFalse(exchange.isAdmin(brian));
        assertFalse(exchange.isOperator(brian));
    }

    function test_CTFExchange_Auth() public {
        vm.expectEmit(true, true, true, true);
        emit NewAdmin(henry, admin);
        emit NewOperator(henry, admin);

        vm.startPrank(admin);
        exchange.addAdmin(henry);
        exchange.addOperator(henry);
        vm.stopPrank();

        assertTrue(exchange.isOperator(henry));
        assertTrue(exchange.isAdmin(henry));
    }

    function test_CTFExchange_Auth_RemoveAdmin() public {
        // First add henry as admin and operator
        vm.startPrank(admin);
        exchange.addAdmin(henry);
        exchange.addOperator(henry);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit RemovedAdmin(henry, admin);
        emit RemovedOperator(henry, admin);

        vm.startPrank(admin);
        exchange.removeAdmin(henry);
        exchange.removeOperator(henry);
        vm.stopPrank();

        assertFalse(exchange.isAdmin(henry));
        assertFalse(exchange.isOperator(henry));
    }

    function test_CTFExchange_Auth_RenounceOperator() public {
        assertTrue(exchange.isOperator(admin));

        vm.prank(admin);
        exchange.renounceOperatorRole();
        assertFalse(exchange.isOperator(admin));
    }

    function test_CTFExchange_Auth_NotAdmin() public {
        vm.expectRevert(NotAdmin.selector);
        exchange.addAdmin(address(1));
    }

    function test_CTFExchange_Auth_revert_RemoveLastAdmin() public {
        // Cannot remove the only admin
        vm.expectRevert(LastAdmin.selector);
        vm.prank(admin);
        exchange.removeAdmin(admin);
    }

    function test_CTFExchange_Auth_revert_RemoveNonAdmin() public {
        vm.expectRevert(NotAdmin.selector);
        vm.prank(admin);
        exchange.removeAdmin(henry);
    }

    function test_CTFExchange_Auth_revert_RemoveNonOperator() public {
        vm.expectRevert(NotOperator.selector);
        vm.prank(admin);
        exchange.removeOperator(henry);
    }

    function test_CTFExchange_Auth_revert_AddExistingAdmin() public {
        vm.expectRevert(AlreadyAdmin.selector);
        vm.prank(admin);
        exchange.addAdmin(admin);
    }

    function test_CTFExchange_Auth_revert_AddExistingOperator() public {
        vm.expectRevert(AlreadyOperator.selector);
        vm.prank(admin);
        exchange.addOperator(admin);
    }

    function test_CTFExchange_Auth_RemoveAdminWithMultiple() public {
        // Add a second admin
        vm.prank(admin);
        exchange.addAdmin(henry);
        assertTrue(exchange.isAdmin(henry));

        // Can remove one of two admins
        vm.prank(admin);
        exchange.removeAdmin(henry);
        assertFalse(exchange.isAdmin(henry));
    }

    function test_CTFExchange_Pause() public {
        vm.expectEmit(true, true, true, false);
        emit TradingPaused(admin);

        vm.prank(admin);
        exchange.pauseTrading();

        uint256 usdcAmount = 50_000_000;
        uint256 tokenAmount = 100_000_000;

        // Deal
        dealUsdcAndApprove(bob, address(exchange), usdcAmount);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, tokenAmount);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, usdcAmount, tokenAmount, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, tokenAmount, usdcAmount, Side.SELL);
        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory makerFillAmounts = new uint256[](1);
        makerFillAmounts[0] = tokenAmount;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.expectRevert(Paused.selector);
        vm.prank(carla);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, usdcAmount, makerFillAmounts, 0, makerFeeAmounts);

        vm.expectEmit(true, true, true, true);
        emit TradingUnpaused(admin);

        vm.prank(admin);
        exchange.unpauseTrading();

        // Order can be filled after unpausing
        vm.prank(carla);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, usdcAmount, makerFillAmounts, 0, makerFeeAmounts);
    }

    function test_CTFExchange_SetUserPauseBlockInterval() public {
        uint256 oldInterval = exchange.userPauseBlockInterval();
        uint256 newInterval = oldInterval + 50;

        vm.expectEmit(true, true, true, true);
        emit UserPauseBlockIntervalUpdated(oldInterval, newInterval);

        vm.prank(admin);
        exchange.setUserPauseBlockInterval(newInterval);

        assertEq(exchange.userPauseBlockInterval(), newInterval);
    }

    function test_CTFExchange_SetFeeReceiver() public {
        address newFeeReceiver = address(0xBEEF);

        vm.expectEmit(true, true, true, true);
        emit FeeReceiverUpdated(newFeeReceiver);

        vm.prank(admin);
        exchange.setFeeReceiver(newFeeReceiver);

        assertEq(exchange.getFeeReceiver(), newFeeReceiver);
    }

    function test_CTFExchange_DefaultMaxFeeRate() public view {
        // Default max fee rate should be 5% (500 bps)
        assertEq(exchange.getMaxFeeRate(), 500);
    }

    function test_CTFExchange_SetMaxFeeRate() public {
        // 10% in bps
        uint256 newMaxFeeRate = 1000;

        vm.expectEmit(true, true, true, true);
        emit MaxFeeRateUpdated(newMaxFeeRate);

        vm.prank(admin);
        exchange.setMaxFeeRate(newMaxFeeRate);

        assertEq(exchange.getMaxFeeRate(), newMaxFeeRate);
    }

    function test_CTFExchange_SetMaxFeeRate_revert_NotAdmin() public {
        vm.expectRevert(NotAdmin.selector);
        vm.prank(bob);
        exchange.setMaxFeeRate(500);
    }

    function test_CTFExchange_SetMaxFeeRate_revert_ExceedsCeiling() public {
        // Cannot set rate >= 10000 bps (100%)
        vm.expectRevert(MaxFeeRateExceedsCeiling.selector);
        vm.prank(admin);
        exchange.setMaxFeeRate(10000);
    }

    function test_CTFExchange_ValidateFee() public view {
        // Fee of 5 USDC on a 100 USDC trade = 5%, should pass
        exchange.validateFee(5_000_000, 100_000_000);

        // Fee of 4 USDC on a 100 USDC trade = 4%, should pass
        exchange.validateFee(4_000_000, 100_000_000);
    }

    function test_CTFExchange_ValidateFee_revert_FeeExceedsMaxRate() public {
        // Fee of 6 USDC on a 100 USDC trade = 6%, should revert
        vm.expectRevert(FeeExceedsMaxRate.selector);
        exchange.validateFee(6_000_000, 100_000_000);
    }

    function test_CTFExchange_ValidateFee_ZeroRate() public {
        vm.prank(admin);
        exchange.setMaxFeeRate(0);
        assertEq(exchange.getMaxFeeRate(), 0);

        exchange.validateFee(99_000_000, 100_000_000);
    }

    function test_CTFExchange_hashOrder() public view {
        Order memory order = _createOrder(bob, 1, 50_000_000, 100_000_000, Side.BUY);

        bytes32 expectedHash = _generateOrderHash(address(exchange), order);

        assertEq(exchange.hashOrder(order), expectedHash);
    }

    function test_CTFExchange_ValidateOrder() public view {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        exchange.validateOrder(order);
    }

    function test_CTFExchange_ValidateOrder_revert_InvalidSig() public {
        Order memory order = _createOrder(bob, yes, 50_000_000, 100_000_000, Side.BUY);

        // Incorrect signature(note: signed by carla)
        order.signature = _signMessage(carlaPK, exchange.hashOrder(order));
        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrder(order);
    }

    function test_CTFExchange_ValidateOrder_revert_InvalidSigLength() public {
        Order memory order = _createOrder(bob, yes, 50_000_000, 100_000_000, Side.BUY);
        order.signature = hex"";
        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrder(order);
    }

    function test_CTFExchange_ValidateOrder_revert_InvalidSignerMaker() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        // For EOA signature type, signer and maker MUST be the same
        order.maker = carla;
        order.signatureType = SignatureType.EOA;
        order.signature = _signMessage(bobPK, exchange.hashOrder(order));

        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrder(order);
    }

    function test_CTFExchange_ValidateOrder_revert_DuplicateOrder() public {
        uint256 usdcAmount = 50_000_000;
        uint256 tokenAmount = 100_000_000;

        // Deal
        dealUsdcAndApprove(bob, address(exchange), usdcAmount);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, tokenAmount);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, usdcAmount, tokenAmount, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, tokenAmount, usdcAmount, Side.SELL);
        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory makerFillAmounts = new uint256[](1);
        makerFillAmounts[0] = tokenAmount;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.prank(carla);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, usdcAmount, makerFillAmounts, 0, makerFeeAmounts);

        // the orders can no longer be filled
        vm.expectRevert(OrderAlreadyFilled.selector);
        exchange.validateOrder(takerOrder);
    }

    function test_CTFExchange_supportsInterface() public view {
        // ERC1155TokenReceiver interface
        assertTrue(exchange.supportsInterface(0x4e2312e0));
        // ERC165 interface
        assertTrue(exchange.supportsInterface(0x01ffc9a7));
        // Unsupported interface
        assertFalse(exchange.supportsInterface(0xdeadbeef));
    }

    function test_CTFExchange_matchOrders_revert_NoMakerOrders() public {
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order[] memory makerOrders = new Order[](0);
        uint256[] memory fillAmounts = new uint256[](0);
        uint256[] memory feeAmounts = new uint256[](0);

        vm.expectRevert(NoMakerOrders.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, feeAmounts);
    }

    function test_CTFExchange_matchOrders_revert_MismatchedArrayLengths() public {
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        // fillAmounts has length 2, mismatched with makerOrders length 1
        uint256[] memory fillAmounts = new uint256[](2);
        uint256[] memory feeAmounts = new uint256[](1);

        vm.expectRevert(MismatchedArrayLengths.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, feeAmounts);
    }

    function test_CTFExchange_UserPausable_revert_UserAlreadyPaused() public {
        vm.prank(bob);
        exchange.pauseUser();

        // Calling pauseUser() again should revert
        vm.expectRevert(UserAlreadyPaused.selector);
        vm.prank(bob);
        exchange.pauseUser();
    }

    function test_CTFExchange_UserPausable_rePauseAfterUnpause() public {
        vm.prank(bob);
        exchange.pauseUser();

        // Unpause first, then re-pause should succeed
        vm.prank(bob);
        exchange.unpauseUser();

        vm.prank(bob);
        exchange.pauseUser();
    }

    function test_CTFExchange_SetUserPauseBlockInterval_revert_ExceedsMax() public {
        vm.expectRevert(ExceedsMaxPauseInterval.selector);
        vm.prank(admin);
        exchange.setUserPauseBlockInterval(302_401);
    }

    function test_CTFExchange_SetUserPauseBlockInterval_MaxValue() public {
        // Setting exactly MAX_PAUSE_BLOCK_INTERVAL (7 days at 2s Polygon blocks) should succeed
        vm.prank(admin);
        exchange.setUserPauseBlockInterval(302_400);
        assertEq(exchange.userPauseBlockInterval(), 302_400);
    }

    function test_CTFExchange_UserPaused_ExactBoundaryBlock() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        vm.prank(bob);
        exchange.pauseUser();

        uint256 pausedAt = exchange.userPausedBlockAt(bob);

        // Advance to exactly blockPausedAt (not one past it)
        vm.roll(pausedAt);

        // User should be paused at exactly blockPausedAt (>= check)
        assertTrue(exchange.isUserPaused(bob));
        vm.expectRevert(UserIsPaused.selector);
        exchange.validateOrder(order);
    }

    function test_CTFExchange_ValidateOrder_UserPaused() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        uint256 blockInterval = exchange.userPauseBlockInterval();

        vm.expectEmit(true, true, true, true);
        emit UserPaused(bob, block.number + blockInterval);

        vm.prank(bob);
        exchange.pauseUser();

        uint256 userPausedAt = exchange.userPausedBlockAt(bob);
        assertEq(userPausedAt, block.number + exchange.userPauseBlockInterval());

        // Advance 50 blocks in the future
        advance(50);

        // The user will not be paused yet
        assertFalse(exchange.isUserPaused(bob));

        // And the order is valid
        exchange.validateOrder(order);

        // Advance another 100 blocks in the future
        advance(100);

        // The user will be paused
        assertTrue(exchange.isUserPaused(bob));

        // And the order validation will correctly revert
        vm.expectRevert(UserIsPaused.selector);
        exchange.validateOrder(order);

        // After unpausing the user will be unpaused and his order will be valid
        vm.expectEmit(true, true, true, true);
        emit UserUnpaused(bob);
        vm.prank(bob);
        exchange.unpauseUser();

        assertFalse(exchange.isUserPaused(bob));
        exchange.validateOrder(order);
    }
}
