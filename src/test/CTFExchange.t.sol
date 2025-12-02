// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { Order, Side, MatchType, OrderStatus, SignatureType } from "src/exchange/libraries/Structs.sol";

contract CTFExchangeTest is BaseExchangeTest {
    event ProxyFactoryUpdated(address indexed oldProxyFactory, address indexed newProxyFactory);
    event SafeFactoryUpdated(address indexed oldSafeFactory, address indexed newSafeFactory);

    function test_setup() public view {
        assertTrue(exchange.isAdmin(admin));
        assertTrue(exchange.isOperator(admin));
        assertFalse(exchange.isAdmin(brian));
        assertFalse(exchange.isOperator(brian));
    }

    function test_Auth() public {
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

    function test_Auth_RemoveAdmin() public {
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

    function test_Auth_NotAdmin() public {
        vm.expectRevert(NotAdmin.selector);
        exchange.addAdmin(address(1));
    }

    function test_Auth_Renounce() public {
        // Non admin cannot renounce
        vm.expectRevert(NotAdmin.selector);
        vm.prank(address(12));
        exchange.renounceAdminRole();

        assertTrue(exchange.isAdmin(admin));
        assertTrue(exchange.isOperator(admin));

        // Successfully renounces the admin role
        vm.prank(admin);
        exchange.renounceAdminRole();
        assertFalse(exchange.isAdmin(admin));
        assertTrue(exchange.isOperator(admin));

        // Successfully renounces the operator role
        vm.prank(admin);
        exchange.renounceOperatorRole();
        assertFalse(exchange.isOperator(admin));
    }

    function test_Pause() public {
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
        exchange.matchOrders(takerOrder, makerOrders, usdcAmount, makerFillAmounts, 0, makerFeeAmounts);

        vm.expectEmit(true, true, true, true);
        emit TradingUnpaused(admin);

        vm.prank(admin);
        exchange.unpauseTrading();

        // Order can be filled after unpausing
        vm.prank(carla);
        exchange.matchOrders(takerOrder, makerOrders, usdcAmount, makerFillAmounts, 0, makerFeeAmounts);
    }

    function test_RegisterToken(uint256 _token0, uint256 _token1, uint256 _conditionId) public {
        vm.assume(
            _token0 != yes && _token0 != no && _token1 != yes && _token1 != no && _token1 != _token0 && _token0 > 0
                && _token1 > 0
        );
        bytes32 tokenConditionId = bytes32(_conditionId);

        vm.expectEmit(true, true, true, false);
        emit TokenRegistered(_token0, _token1, tokenConditionId);
        emit TokenRegistered(_token1, _token0, tokenConditionId);
        vm.prank(admin);
        exchange.registerToken(_token0, _token1, tokenConditionId);

        assertEq(exchange.getComplement(_token0), _token1);
        assertEq(exchange.getComplement(_token1), _token0);
        assertEq(exchange.getConditionId(_token0), tokenConditionId);
    }

    function test_RegisterToken_Revert_Cases() public {
        vm.startPrank(admin);
        vm.expectRevert(InvalidTokenId.selector);
        exchange.registerToken(0, 0, bytes32(0));

        vm.expectRevert(AlreadyRegistered.selector);
        exchange.registerToken(no, yes, bytes32(0));
    }

    function test_SetProxyFactory() public {
        address oldProxyFactory = exchange.getProxyFactory();
        address newProxyFactory = address(0x12345);

        vm.expectEmit(true, true, true, true);
        emit ProxyFactoryUpdated(oldProxyFactory, newProxyFactory);

        vm.prank(admin);
        exchange.setProxyFactory(newProxyFactory);

        assertEq(exchange.getProxyFactory(), newProxyFactory);
    }

    function test_SetSafeFactory() public {
        address oldSafeFactory = exchange.getSafeFactory();
        address newSafeFactory = address(0x98765);

        vm.expectEmit(true, true, true, true);
        emit SafeFactoryUpdated(oldSafeFactory, newSafeFactory);

        vm.prank(admin);
        exchange.setSafeFactory(newSafeFactory);

        assertEq(exchange.getSafeFactory(), newSafeFactory);
    }

    function test_SetUserPauseBlockInterval() public {
        uint256 oldInterval = exchange.userPauseBlockInterval();
        uint256 newInterval = oldInterval + 50;

        vm.expectEmit(true, true, true, true);
        emit UserPauseBlockIntervalUpdated(oldInterval, newInterval);

        vm.prank(admin);
        exchange.setUserPauseBlockInterval(newInterval);

        assertEq(exchange.userPauseBlockInterval(), newInterval);
    }

    function test_SetFeeReceiver() public {
        address newFeeReceiver = address(0xBEEF);

        vm.expectEmit(true, true, true, true);
        emit FeeReceiverUpdated(newFeeReceiver);

        vm.prank(admin);
        exchange.setFeeReceiver(newFeeReceiver);

        assertEq(exchange.getFeeReceiver(), newFeeReceiver);
    }

    function test_hashOrder() public view {
        Order memory order = _createOrder(bob, 1, 50_000_000, 100_000_000, Side.BUY);

        bytes32 expectedHash = _generateOrderHash(address(exchange), order);

        assertEq(exchange.hashOrder(order), expectedHash);
    }

    function test_ValidateOrder() public view {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        exchange.validateOrder(order);
    }

    function test_ValidateOrder_revert_InvalidSig() public {
        Order memory order = _createOrder(bob, yes, 50_000_000, 100_000_000, Side.BUY);

        // Incorrect signature(note: signed by carla)
        order.signature = _signMessage(carlaPK, exchange.hashOrder(order));
        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrder(order);
    }

    function test_ValidateOrder_revert_InvalidSigLength() public {
        Order memory order = _createOrder(bob, yes, 50_000_000, 100_000_000, Side.BUY);
        order.signature = hex"";
        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrder(order);
    }

    function test_ValidateOrder_revert_InvalidSignerMaker() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        // For EOA signature type, signer and maker MUST be the same
        order.maker = carla;
        order.signatureType = SignatureType.EOA;
        order.signature = _signMessage(bobPK, exchange.hashOrder(order));

        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrder(order);
    }

    function test_ValidateOrder_revert_InvalidExpiration() public {
        Order memory order = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        vm.warp(block.timestamp + 1000);
        order.expiration = 50;
        vm.expectRevert(OrderExpired.selector);
        exchange.validateOrder(order);
    }

    function test_ValidateOrder_revert_DuplicateOrder() public {
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
        exchange.matchOrders(takerOrder, makerOrders, usdcAmount, makerFillAmounts, 0, makerFeeAmounts);

        // the orders can no longer be filled
        vm.expectRevert(OrderAlreadyFilled.selector);
        exchange.validateOrder(takerOrder);
    }

    function test_ValidateOrder_UserPaused() public {
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

    function test_ValidateOrderFee_revert_MaxFeeExceeded() public {
        uint256 maxFillFee = 5_000_000; // max fill fee of 5 USDC
        vm.expectRevert(MaxFeeExceeded.selector);
        exchange.validateOrderFee(maxFillFee, 10_000_000); // operator fee of 10 USDC
    }
}
