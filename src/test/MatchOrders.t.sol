// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { Order, Side } from "src/exchange/libraries/Structs.sol";

contract MatchOrdersTest is BaseExchangeTest {
    function test_MatchOrders_Complementary() public {
        vm.pauseGasMetering();
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 60_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 150_000_000);
        vm.resumeGasMetering();

        // Init a match with a yes buy against a list of yes sells
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 60_000_000, 100_000_000, Side.BUY);
        Order memory makerOrderA = _createAndSignOrder(carlaPK, yes, 50_000_000, 25_000_000, Side.SELL);
        Order memory makerOrderB = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);
        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = makerOrderA;
        makerOrders[1] = makerOrderB;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 50_000_000;
        fillAmounts[1] = 70_000_000;

        checkpointCollateral(carla);
        checkpointCTF(bob, yes);

        // Check fill events
        // First maker order is filled completely
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(makerOrderA),
            carla,
            bob,
            Side.SELL,
            yes,
            50_000_000,
            25_000_000,
            0,
            bytes32(0),
            bytes32(0)
        );

        // Second maker order is partially filled
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(makerOrderB),
            carla,
            bob,
            Side.SELL,
            yes,
            70_000_000,
            35_000_000,
            0,
            bytes32(0),
            bytes32(0)
        );
        // The taker order is filled completely
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(takerOrder),
            bob,
            address(exchange),
            Side.BUY,
            yes,
            60_000_000,
            120_000_000,
            0,
            bytes32(0),
            bytes32(0)
        );

        vm.expectEmit(true, true, true, true);
        emit OrdersMatched(exchange.hashOrder(takerOrder), bob, Side.BUY, yes, 60_000_000, 120_000_000);

        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 0;
        makerFeeAmounts[1] = 0;

        vm.prank(admin);
        exchange.matchOrders(takerOrder, makerOrders, 60_000_000, fillAmounts, takerFeeAmount, makerFeeAmounts);

        // Ensure balances have been updated post match
        assertCollateralBalance(carla, 60_000_000);
        assertCTFBalance(bob, yes, 120_000_000);

        // Ensure onchain state for orders is as expected
        // The taker order is fully filled
        bytes32 takerOrderHash = exchange.hashOrder(takerOrder);
        assertEq(exchange.getOrderStatus(takerOrderHash).remaining, 0);
        assertTrue(exchange.getOrderStatus(takerOrderHash).filled);
    }

    function test_MatchOrders_Mint() public {
        vm.pauseGasMetering();
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 60_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 50_000_000);
        dealUsdcAndApprove(carla, address(exchange), 16_000_000);
        vm.resumeGasMetering();

        // Init Match with YES buy against a YES sell and a NO buy
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 60_000_000, 100_000_000, Side.BUY);
        Order memory makerOrderSell = _createAndSignOrder(carlaPK, yes, 50_000_000, 25_000_000, Side.SELL);
        Order memory makerOrderBuy = _createAndSignOrder(carlaPK, no, 16_000_000, 40_000_000, Side.BUY);
        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = makerOrderSell;
        makerOrders[1] = makerOrderBuy;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 50_000_000;
        fillAmounts[1] = 16_000_000;

        uint256 takerOrderFillAmount = 49_000_000;

        checkpointCollateral(carla);
        checkpointCTF(bob, yes);
        checkpointCTF(carla, no);

        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 0;
        makerFeeAmounts[1] = 0;

        vm.prank(admin);
        exchange.matchOrders(
            takerOrder, makerOrders, takerOrderFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        // Ensure balances have been updated post match
        assertCTFBalance(bob, yes, 90_000_000);

        assertCollateralBalance(carla, 9_000_000);
        assertCTFBalance(carla, no, 40_000_000);

        // Ensure onchain state for orders is as expected
        // The taker order is partially filled
        assertEq(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).remaining, 11_000_000);
        assertFalse(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).filled);

        // The maker orders get completely filled
        assertEq(exchange.getOrderStatus(exchange.hashOrder(makerOrderSell)).remaining, 0);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(makerOrderSell)).filled);

        assertEq(exchange.getOrderStatus(exchange.hashOrder(makerOrderBuy)).remaining, 0);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(makerOrderBuy)).filled);
    }

    function test_MatchOrders_Merge() public {
        // Deals
        vm.pauseGasMetering();
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, 75_000_000);
        dealUsdcAndApprove(carla, address(exchange), 24_000_000);
        vm.resumeGasMetering();

        // Init Match with YES sell against a NO sell and a Yes buy
        // To match the YES sell with the NO sell, CTF Exchange will MERGE Outcome tokens into collateral
        // Then will fill the YES sell and the NO sell with the resulting collateral
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 60_000_000, Side.SELL);

        Order memory makerOrderSell = _createAndSignOrder(carlaPK, no, 75_000_000, 30_000_000, Side.SELL);
        Order memory makerOrderBuy = _createAndSignOrder(carlaPK, yes, 24_000_000, 40_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = makerOrderSell;
        makerOrders[1] = makerOrderBuy;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 75_000_000;
        fillAmounts[1] = 15_000_000;

        uint256 takerOrderFillAmount = 100_000_000;

        checkpointCollateral(bob);

        checkpointCTF(carla, yes);
        checkpointCollateral(carla);

        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 0;
        makerFeeAmounts[1] = 0;

        vm.prank(admin);
        exchange.matchOrders(
            takerOrder, makerOrders, takerOrderFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        // Ensure balances have been updated post match
        assertCollateralBalance(bob, 60_000_000);

        assertCTFBalance(carla, yes, 25_000_000);
        assertCollateralBalance(carla, 15_000_000);

        // Ensure onchain state for orders is as expected
        // The taker order is fully filled
        assertEq(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).remaining, 0);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).filled);

        // The first maker order gets completely filled
        assertEq(exchange.getOrderStatus(exchange.hashOrder(makerOrderSell)).remaining, 0);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(makerOrderSell)).filled);

        // The second maker order is partially filled
        assertEq(exchange.getOrderStatus(exchange.hashOrder(makerOrderBuy)).remaining, 9_000_000);
        assertFalse(exchange.getOrderStatus(exchange.hashOrder(makerOrderBuy)).filled);
    }

    function test_MatchOrders_Complementary_Fees() public {
        vm.pauseGasMetering();
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 55_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);
        vm.resumeGasMetering();

        // Initialize a YES BUY taker order at 50c with a 5 USDC max fee
        uint256 takerFeeAmount = 5_000_000;
        Order memory takerOrder =
            _createAndSignOrderWithFee(bobPK, yes, 50_000_000, 100_000_000, takerFeeAmount, Side.BUY);

        // Initialiaze a YES SELL order at 50c with a 10c USDC max fee
        uint256 makerFeeAmount = 100_000;
        Order memory makerOrder =
            _createAndSignOrderWithFee(carlaPK, yes, 100_000_000, 50_000_000, makerFeeAmount, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        // Assert event emissions
        vm.expectEmit(true, true, true, true);
        emit FeeCharged(feeReceiver, makerFeeAmount);
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(makerOrder),
            carla,
            bob,
            Side.SELL,
            yes,
            100_000_000,
            50_000_000,
            makerFeeAmount,
            bytes32(0),
            bytes32(0)
        );

        vm.expectEmit(true, true, true, true);
        emit FeeCharged(feeReceiver, takerFeeAmount);
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(takerOrder),
            bob,
            address(exchange),
            Side.BUY,
            yes,
            50_000_000,
            100_000_000,
            takerFeeAmount,
            bytes32(0),
            bytes32(0)
        );

        // Assert state pre match
        assertCollateralBalance(bob, 55_000_000);
        assertCTFBalance(carla, yes, 100_000_000);

        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(carla, 0);

        // Match the orders
        vm.prank(admin);
        exchange.matchOrders(takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts);

        // Assert state changes post match
        // Taker: YES BUY fully filled, receiving Outcome Tokens, spending Collateral + taker fee
        // Assert Outcome tokens received
        assertCTFBalance(bob, yes, 100_000_000);
        // Assert Collateral spent
        assertCollateralBalance(bob, 0);

        // Maker: Sell is fully filled, receiving Collateral - maker fee, spending Outcome Tokens
        assertCollateralBalance(carla, 49_900_000);
        assertCTFBalance(carla, yes, 0);

        // Fees are collected from both orders
        // The taker fee as an additional deduction from the taker's collateral balance
        // The maker fee as a deduction from the maker's collateral proceeds
        // Transferred to the fee receiver
        assertCollateralBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrders_Mint_Fees() public {
        vm.pauseGasMetering();
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 55_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_100_000);
        vm.resumeGasMetering();

        // Initialize a YES BUY taker order at 50c with a 5 USDC max fee
        uint256 takerFeeAmount = 5_000_000;
        Order memory takerOrder =
            _createAndSignOrderWithFee(bobPK, yes, 50_000_000, 100_000_000, takerFeeAmount, Side.BUY);

        // Initialiaze a NO BUY order at 50c with a 10c USDC max fee
        uint256 makerFeeAmount = 100_000;
        Order memory makerOrder =
            _createAndSignOrderWithFee(carlaPK, no, 50_000_000, 100_000_000, makerFeeAmount, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        // Assert event emissions
        vm.expectEmit(true, true, true, true);
        emit FeeCharged(feeReceiver, makerFeeAmount);
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(makerOrder),
            carla,
            bob,
            Side.BUY,
            no,
            50_000_000,
            100_000_000,
            makerFeeAmount,
            bytes32(0),
            bytes32(0)
        );

        vm.expectEmit(true, true, true, true);
        emit FeeCharged(feeReceiver, takerFeeAmount);
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(takerOrder),
            bob,
            address(exchange),
            Side.BUY,
            yes,
            50_000_000,
            100_000_000,
            takerFeeAmount,
            bytes32(0),
            bytes32(0)
        );

        // Assert state pre match
        assertCollateralBalance(bob, 55_000_000);
        assertCollateralBalance(carla, 50_100_000);

        assertCTFBalance(bob, yes, 0);
        assertCTFBalance(carla, no, 0);

        // Match the orders
        vm.prank(admin);
        exchange.matchOrders(takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts);

        // Assert state changes post match
        assertCTFBalance(bob, yes, 100_000_000);
        assertCollateralBalance(bob, 0);

        assertCTFBalance(carla, no, 100_000_000);
        assertCollateralBalance(carla, 0);

        // Fees collected from both orders
        assertCollateralBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrders_Merge_Fees() public {
        vm.pauseGasMetering();
        // Deals
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);
        vm.resumeGasMetering();

        // Initialize a YES SELL taker order at 50c with a 5 USDC max fee
        uint256 takerFeeAmount = 5_000_000;
        Order memory takerOrder =
            _createAndSignOrderWithFee(bobPK, yes, 100_000_000, 50_000_000, takerFeeAmount, Side.SELL);

        // Initialiaze a NO SELL order at 50c with a 10c USDC max fee
        uint256 makerFeeAmount = 100_000;
        Order memory makerOrder =
            _createAndSignOrderWithFee(carlaPK, no, 100_000_000, 50_000_000, makerFeeAmount, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        // Assert event emissions
        vm.expectEmit(true, true, true, true);
        emit FeeCharged(feeReceiver, makerFeeAmount);
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(makerOrder),
            carla,
            bob,
            Side.SELL,
            no,
            100_000_000,
            50_000_000,
            makerFeeAmount,
            bytes32(0),
            bytes32(0)
        );

        vm.expectEmit(true, true, true, true);
        emit FeeCharged(feeReceiver, takerFeeAmount);
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(takerOrder),
            bob,
            address(exchange),
            Side.SELL,
            yes,
            100_000_000,
            50_000_000,
            takerFeeAmount,
            bytes32(0),
            bytes32(0)
        );

        // Assert state pre match
        assertCollateralBalance(bob, 0);
        assertCollateralBalance(carla, 0);

        assertCTFBalance(bob, yes, 100_000_000);
        assertCTFBalance(carla, no, 100_000_000);

        // Match the orders
        vm.prank(admin);
        exchange.matchOrders(takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts);

        // Assert state changes post match
        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 45_000_000);

        assertCTFBalance(carla, no, 0);
        assertCollateralBalance(carla, 49_900_000);

        // Fees collected from both orders
        assertCollateralBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrders_Complementary_Fees_Surplus() public {
        vm.pauseGasMetering();
        // Deals
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealUsdcAndApprove(carla, address(exchange), 60_100_000);
        vm.resumeGasMetering();

        // Initialize a YES SELL taker order at 50c with a 5 USDC max fee
        uint256 takerFeeAmount = 5_000_000;
        Order memory takerOrder =
            _createAndSignOrderWithFee(bobPK, yes, 100_000_000, 50_000_000, takerFeeAmount, Side.SELL);

        // Initialiaze a YES BUY order at 60c with a 10c USDC max fee, creating a surplus
        uint256 makerFeeAmount = 100_000;
        Order memory makerOrder =
            _createAndSignOrderWithFee(carlaPK, yes, 60_000_000, 100_000_000, makerFeeAmount, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 60_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        // Assert event emissions
        vm.expectEmit(true, true, true, true);
        emit FeeCharged(feeReceiver, makerFeeAmount);
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(makerOrder),
            carla,
            bob,
            Side.BUY,
            yes,
            60_000_000,
            100_000_000,
            makerFeeAmount,
            bytes32(0),
            bytes32(0)
        );

        vm.expectEmit(true, true, true, true);
        emit FeeCharged(feeReceiver, takerFeeAmount);
        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            exchange.hashOrder(takerOrder),
            bob,
            address(exchange),
            Side.SELL,
            yes,
            100_000_000,
            60_000_000,
            takerFeeAmount,
            bytes32(0),
            bytes32(0)
        );

        // Assert state pre match
        assertCTFBalance(bob, yes, 100_000_000);
        assertCollateralBalance(carla, 60_100_000);

        assertCollateralBalance(bob, 0);
        assertCTFBalance(carla, yes, 0);

        // Match the orders
        vm.prank(admin);
        exchange.matchOrders(takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts);

        // Assert state changes post match
        assertCTFBalance(bob, yes, 0);
        // Receives 50 USDC from sale + 10 USDC surplus from maker buy order - 5 USDC taker fee
        assertCollateralBalance(bob, 55_000_000);

        // Deducted both 60 USDC buy cost + 0.1 USDC maker fee
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, yes, 100_000_000);

        // Fees are collected from both orders
        assertCollateralBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrders_TakerRefund() public {
        vm.pauseGasMetering();
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);
        vm.resumeGasMetering();

        // Init match with takerFillAmount >> amount needed to fill the maker orders
        // The excess tokens should be refunded to the taker
        Order memory buy = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        Order memory sell = _createAndSignOrder(carlaPK, yes, 100_000_000, 40_000_000, Side.SELL);
        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // If fill amount is miscalculated, refund the caller any leftover tokens
        // In this test, 40 USDC is needed to fill the sell.
        // The Exchange will refund the taker order maker 10 USDC
        uint256 takerFillAmount = 50_000_000;
        uint256 expectedRefund = 10_000_000;

        vm.expectEmit(true, true, true, true);
        // Assert the refund transfer to the taker order maker
        emit Transfer(address(exchange), bob, expectedRefund);

        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerFillAmount, fillAmounts, 0, makerFeeAmounts);

        // Check state post match
        assertCollateralBalance(bob, expectedRefund);
        assertCTFBalance(bob, yes, 100_000_000);
    }

    // /*//////////////////////////////////////////////////////////////
    //                            FAIL CASES
    // //////////////////////////////////////////////////////////////*/

    function test_MatchOrders_revert_FeeExceedsProceeds() public {
        // Deals
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);

        // Initialize a YES SELL taker order, selling 100 YES at 50c with a 100 USDC max fee
        // an absurdly high max fee
        uint256 takerMaxFeeAmount = 100_000_000;
        Order memory takerOrder =
            _createAndSignOrderWithFee(bobPK, yes, 100_000_000, 50_000_000, takerMaxFeeAmount, Side.SELL);

        // Initialiaze a YES BUY order at 50c
        Order memory makerOrder = _createAndSignOrderWithFee(carlaPK, yes, 50_000_000, 100_000_000, 0, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // The operator levys an absurdly high taker fee of 60 USDC that exceeds the proceeds from the trade
        uint256 takerFeeAmount = 60_000_000;

        vm.expectRevert(FeeExceedsProceeds.selector);
        // Match the orders
        vm.prank(admin);
        exchange.matchOrders(takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts);
    }

    function test_MatchOrders_revert_MaxFeeExceeded() public {
        // Deals
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);

        // Initialize a YES SELL taker order, selling 100 YES at 50c with a 5 USDC max fee
        // an absurdly high max fee
        uint256 takerMaxFeeAmount = 5_000_000;
        Order memory takerOrder =
            _createAndSignOrderWithFee(bobPK, yes, 100_000_000, 50_000_000, takerMaxFeeAmount, Side.SELL);

        // Initialiaze a YES BUY order at 50c
        Order memory makerOrder = _createAndSignOrderWithFee(carlaPK, yes, 50_000_000, 100_000_000, 0, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // The operator levys an absurdly high taker fee of 60 USDC that exceeds the taker's max fee
        uint256 takerFeeAmount = 60_000_000;

        vm.expectRevert(MaxFeeExceeded.selector);
        // Match the orders
        vm.prank(admin);
        exchange.matchOrders(takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts);
    }

    function test_MatchOrders_revert_NotCrossingSells() public {
        // Deals
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);

        // 60c YES sell
        Order memory yesSell = _createAndSignOrder(bobPK, yes, 100_000_000, 60_000_000, Side.SELL);

        // 60c NO sell
        Order memory noSell = _createAndSignOrder(carlaPK, no, 100_000_000, 60_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = noSell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        uint256 takerOrderFillAmount = 100_000_000;

        // Sells can only match if priceYesSell + priceNoSell < 1
        vm.expectRevert(NotCrossing.selector);
        vm.prank(admin);
        exchange.matchOrders(yesSell, makerOrders, takerOrderFillAmount, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_revert_NotCrossingBuys() public {
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealUsdcAndApprove(carla, address(exchange), 40_000_000);

        // 50c YES buy
        Order memory yesBuy = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // 40c NO buy
        Order memory noBuy = _createAndSignOrder(carlaPK, no, 40_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = noBuy;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 40_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        uint256 takerOrderFillAmount = 50_000_000;

        // Buys can only match if priceYesBuy + priceNoBuy > 1
        vm.expectRevert(NotCrossing.selector);
        vm.prank(admin);
        exchange.matchOrders(yesBuy, makerOrders, takerOrderFillAmount, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_revert_NotCrossingBuyVsSell() public {
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        // 50c YES buy
        Order memory buy = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // 60c YES sell
        Order memory sell = _createAndSignOrder(carlaPK, yes, 100_000_000, 60_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 0;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        uint256 takerOrderFillAmount = 0;

        vm.expectRevert(NotCrossing.selector);
        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerOrderFillAmount, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_revert_InvalidTrade() public {
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);

        Order memory buy = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory sell = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        uint256 takerOrderFillAmount = 50_000_000;

        // Attempt to match a yes buy with a no sell, reverts as this is invalid
        vm.expectRevert(MismatchedTokenIds.selector);
        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerOrderFillAmount, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_ZeroTakerAmount() public {
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 1);

        // Create a non-standard buy order with zero taker amount
        Order memory buy = _createAndSignOrder(bobPK, yes, 50_000_000, 0, Side.BUY);

        // Any valid sell order will be able to drain the buy order
        // Init a sell order priced absurdly high
        Order memory sell = _createAndSignOrder(carlaPK, yes, 1, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 1;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        uint256 takerOrderFillAmount = 50_000_000;

        // The orders are successfully matched
        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerOrderFillAmount, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_revert_InvalidFillAmount() public {
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 1_000_000_000);

        Order memory buy = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        Order memory sell = _createAndSignOrder(carlaPK, yes, 1_000_000_000, 500_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = sell;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 1_000_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        uint256 takerOrderFillAmount = 500_000_000;

        // Attempt to match the above buy and sell, with fillAmount >>> the maker amount of the buy
        // Reverts
        vm.expectRevert(MakingGtRemaining.selector);
        vm.prank(admin);
        exchange.matchOrders(buy, makerOrders, takerOrderFillAmount, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_revert_MaxFeeExceeded_Buy() public {
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 51_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 1_000_000_000);

        // Create a BUY taker order
        uint256 maxFee = 5_000_000; // 5 USDC max fee
        Order memory takerOrder = _createAndSignOrderWithFee(bobPK, yes, 50_000_000, 100_000_000, maxFee, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 20_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // partially fill the buy order
        uint256 takerOrderFillAmount = 10_000_000;

        // The fee charged must be <= the max fee denoted by the order, taking into account the fill amount
        uint256 maxFeeForFill = (maxFee * takerOrderFillAmount) / takerOrder.makerAmount;
        // Set a taker fee that exceeds the max fee for the fill amount
        uint256 takerFeeAmount = maxFeeForFill + 1;

        // throws
        vm.expectRevert(MaxFeeExceeded.selector);
        vm.prank(admin);
        exchange.matchOrders(
            takerOrder, makerOrders, takerOrderFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );
    }

    function test_MatchOrders_revert_MaxFeeExceeded_Sell() public {
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 51_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 1_000_000_000);

        // Create a SELL taker order
        uint256 maxFee = 5_000_000; // 5 USDC max fee
        Order memory takerOrder = _createAndSignOrderWithFee(bobPK, yes, 100_000_000, 50_000_000, maxFee, Side.SELL);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 25_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // partially fill the taker order, with 50 YES sold
        uint256 takerOrderFillAmount = 50_000_000;

        // The fee charged must be <= the max fee denoted by the order, taking into account the fill amount
        uint256 maxFeeForFill = (maxFee * takerOrderFillAmount) / takerOrder.makerAmount;
        // Set a taker fee that exceeds the max fee for the fill amount
        uint256 takerFeeAmount = maxFeeForFill + 1;

        // throws
        vm.expectRevert(MaxFeeExceeded.selector);
        vm.prank(admin);
        exchange.matchOrders(
            takerOrder, makerOrders, takerOrderFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );
    }
}
