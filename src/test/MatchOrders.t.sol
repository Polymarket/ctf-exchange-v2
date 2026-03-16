// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { Order, Side } from "src/exchange/libraries/Structs.sol";

contract MatchOrdersTest is BaseExchangeTest {
    function test_MatchOrders_Complementary() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        // Taker: YES BUY - spending 50 USDC to receive 100 YES
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        // Maker: YES SELL - spending 100 YES to receive 50 USDC
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        vm.pauseGasMetering();
        // Taker spent 50 USDC, received 100 YES
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        // Maker spent 100 YES, received 50 USDC
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 50_000_000);
        // Both orders fully filled
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).filled);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(makerOrder)).filled);
    }

    function test_MatchOrders_Mint() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);

        // Taker: YES BUY - spending 50 USDC to receive 100 YES
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        // Maker: NO BUY - spending 50 USDC to receive 100 NO
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        vm.pauseGasMetering();
        // Taker: spent 50 USDC, received 100 YES
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        // Maker: spent 50 USDC, received 100 NO
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, no, 100_000_000);
        // Both orders fully filled
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).filled);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(makerOrder)).filled);
    }

    function test_MatchOrders_Merge() public {
        vm.pauseGasMetering();
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);

        // Taker: YES SELL - spending 100 YES to receive 50 USDC
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);
        // Maker: NO SELL - spending 100 NO to receive 50 USDC
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        vm.pauseGasMetering();
        // Taker: spent 100 YES, received 50 USDC
        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 50_000_000);
        // Maker: spent 100 NO, received 50 USDC
        assertCTFBalance(carla, no, 0);
        assertCollateralBalance(carla, 50_000_000);
        // Both orders fully filled
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).filled);
        assertTrue(exchange.getOrderStatus(exchange.hashOrder(makerOrder)).filled);
    }

    function test_MatchOrders_Complementary_Fees() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 52_500_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        // Taker: YES BUY at 50c with 2.5 USDC fee
        uint256 takerFeeAmount = 2_500_000;
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // Maker: YES SELL at 50c with 0.1 USDC fee
        uint256 makerFeeAmount = 100_000;
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        vm.pauseGasMetering();
        // Taker: spent 52.5 USDC, received 100 YES
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        // Maker: spent 100 YES, received 49.9 USDC (50 - 0.1 fee)
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 49_900_000);
        // Fees collected
        assertCollateralBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrders_Mint_Fees() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 52_500_000);
        dealUsdcAndApprove(carla, address(exchange), 50_100_000);

        // Taker: YES BUY at 50c with 2.5 USDC fee
        uint256 takerFeeAmount = 2_500_000;
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // Maker: NO BUY at 50c with 0.1 USDC fee
        uint256 makerFeeAmount = 100_000;
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        vm.pauseGasMetering();
        // Taker: spent 52.5 USDC, received 100 YES
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        // Maker: spent 50.1 USDC, received 100 NO
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, no, 100_000_000);
        // Fees collected
        assertCollateralBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrders_Merge_Fees() public {
        vm.pauseGasMetering();
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);

        // Taker: YES SELL at 50c with 2.5 USDC fee
        uint256 takerFeeAmount = 2_500_000;
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);

        // Maker: NO SELL at 50c with 0.1 USDC fee
        uint256 makerFeeAmount = 100_000;
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        vm.pauseGasMetering();
        // Taker: spent 100 YES, received 47.5 USDC (50 - 2.5 fee)
        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 47_500_000);
        // Maker: spent 100 NO, received 49.9 USDC (50 - 0.1 fee)
        assertCTFBalance(carla, no, 0);
        assertCollateralBalance(carla, 49_900_000);
        // Fees collected
        assertCollateralBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrders_Complementary_Fees_Surplus() public {
        vm.pauseGasMetering();
        // Taker has 100 YES, Maker has 60.1 USDC (60 + 0.1 fee)
        // Maker buys at 60c but seller only wants 50c, creating 10 USDC surplus for taker
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealUsdcAndApprove(carla, address(exchange), 60_100_000);

        // Taker: YES SELL at 50c with 2.5 USDC fee
        uint256 takerFeeAmount = 2_500_000;
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);

        // Maker: YES BUY at 60c with 0.1 USDC fee (overpays by 10 USDC)
        uint256 makerFeeAmount = 100_000;
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 60_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 60_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        vm.pauseGasMetering();
        // Taker spent 100 YES, received 57.5 USDC (50 + 10 surplus - 2.5 fee)
        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 57_500_000);
        // Maker spent 60.1 USDC, received 100 YES
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, yes, 100_000_000);
        // Fees collected
        assertCollateralBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrders_TakerRefund() public {
        vm.pauseGasMetering();
        // Taker overpays - only 40 USDC needed but 50 sent, so 10 refunded
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        // Taker: YES BUY at 50c
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // Maker: YES SELL at 40c (cheaper than taker's limit)
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 40_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, makerFeeAmounts);

        vm.pauseGasMetering();
        // Taker: sent 50 USDC, only 40 needed, got 10 refund + 100 YES
        assertCollateralBalance(bob, 10_000_000);
        assertCTFBalance(bob, yes, 100_000_000);
        // Maker: spent 100 YES, received 40 USDC
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 40_000_000);
    }

    // /*//////////////////////////////////////////////////////////////
    //                            FAIL CASES
    // //////////////////////////////////////////////////////////////*/

    function test_MatchOrders_revert_FeeExceedsProceeds() public {
        // Deals
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);

        // Disable max fee rate check to test FeeExceedsProceeds
        vm.prank(admin);
        exchange.setMaxFeeRate(0);

        // Initialize a YES SELL taker order, selling 100 YES at 50c
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);

        // Initialize a YES BUY order at 50c
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // The operator levys an absurdly high taker fee of 60 USDC that exceeds the 50 USDC proceeds
        uint256 takerFeeAmount = 60_000_000;

        vm.expectRevert(FeeExceedsProceeds.selector);
        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );
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
        exchange.matchOrders(conditionId, yesSell, makerOrders, takerOrderFillAmount, fillAmounts, 0, makerFeeAmounts);
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
        exchange.matchOrders(conditionId, yesBuy, makerOrders, takerOrderFillAmount, fillAmounts, 0, makerFeeAmounts);
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
        exchange.matchOrders(conditionId, buy, makerOrders, takerOrderFillAmount, fillAmounts, 0, makerFeeAmounts);
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
        exchange.matchOrders(conditionId, buy, makerOrders, takerOrderFillAmount, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_ZeroTakerAmount() public {
        vm.pauseGasMetering();
        // Edge case: buy order with zero taker amount
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 1);

        // Taker: YES BUY with zero taker amount (will accept any price)
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 0, Side.BUY);

        // Maker: YES SELL at absurd price (1 YES for 50 USDC)
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 1, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 1;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, makerFeeAmounts);

        vm.pauseGasMetering();
        // Taker spent 50 USDC, received 1 YES
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 1);
        // Maker spent 1 YES, received 50 USDC
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 50_000_000);
    }

    function test_MatchOrders_revert_InvalidFillAmount() public {
        // Deals
        // Fund taker sufficiently so the match reaches the final taker status check.
        dealUsdcAndApprove(bob, address(exchange), 500_000_000);
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
        exchange.matchOrders(conditionId, buy, makerOrders, takerOrderFillAmount, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_revert_ZeroMakerAmount() public {
        // An order with makerAmount=0 should be rejected, not silently marked as filled
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory zeroMakerOrder = _createAndSignOrder(carlaPK, yes, 0, 0, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = zeroMakerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 0;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.expectRevert(ZeroMakerAmount.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_revert_ZeroMakerAmount_Taker() public {
        // Taker order with makerAmount=0 should also be rejected
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        Order memory zeroTakerOrder = _createAndSignOrder(bobPK, yes, 0, 0, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.expectRevert(ZeroMakerAmount.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, zeroTakerOrder, makerOrders, 0, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_revert_ComplementaryFillExceedsTakerFill_Overspend() public {
        // Fund taker sufficiently so the match reaches the final aggregate fill check.
        dealUsdcAndApprove(bob, address(exchange), 200_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        // Taker: BUY 50 YES for up to 100 USDC (2.00 price limit)
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.BUY);
        // Maker: SELL 100 YES for 150 USDC (1.50 price, still crossing with taker)
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 150_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // Maker execution implies 150 USDC of taker spend, but operator understates taker fill as 100 USDC.
        vm.expectRevert(ComplementaryFillExceedsTakerFill.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 100_000_000, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_Complementary_ConsumesActualTakerFill_WhenPriceImproves() public {
        dealUsdcAndApprove(bob, address(exchange), 100_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 10_000_000);

        // Taker: BUY 100 YES for 100 USDC (1.00 price limit)
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 100_000_000, Side.BUY);
        // Maker: SELL only 10 YES for 10 USDC
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 10_000_000, 10_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 10_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 100_000_000, fillAmounts, 0, makerFeeAmounts);

        assertFalse(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).filled);
        assertEq(exchange.getOrderStatus(exchange.hashOrder(takerOrder)).remaining, 90_000_000);
        assertCollateralBalance(bob, 90_000_000);
        assertCTFBalance(bob, yes, 10_000_000);
    }

    function test_MatchOrders_revert_FeeExceedsMaxRate_Sell() public {
        // Deals
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);

        // Initialize a YES SELL taker order, selling 100 YES at 50c
        // For SELL: cash value = takingAmount = 50 USDC
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);

        // Initialize a YES BUY order at 50c
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // For SELL: cash value = 50 USDC (taking amount)
        // Try to charge 3 USDC (6%) - should revert
        uint256 takerFeeAmount = 3_000_000;

        vm.expectRevert(FeeExceedsMaxRate.selector);
        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );
    }

    function test_MatchOrders_revert_FeeExceedsMaxRate_Buy() public {
        // Deals
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        // Initialize a YES BUY taker order, buying 100 YES at 50c
        // For BUY: cash value = makingAmount = 50 USDC
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // Initialize a YES SELL order at 50c
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // For BUY: cash value = 50 USDC
        // Try to charge 3 USDC, 6%, reverts
        uint256 takerFeeAmount = 3_000_000;

        vm.expectRevert(FeeExceedsMaxRate.selector);
        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );
    }

    function test_MatchOrders_revert_FeeExceedsMaxRate_BuyWithNoMakersAndZeroFill() public {
        uint256 takerFillAmount = 50_000_000;
        uint256 totalExpectedSpend = 52_500_000;

        dealUsdcAndApprove(bob, address(exchange), totalExpectedSpend);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, takerFillAmount, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](0);
        uint256[] memory fillAmounts = new uint256[](0);
        uint256[] memory makerFeeAmounts = new uint256[](0);

        vm.expectRevert(NoMakerOrders.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 0, fillAmounts, totalExpectedSpend, makerFeeAmounts);
    }

    function test_MatchOrders_WithMaxFeeRate_Sell() public {
        vm.pauseGasMetering();
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);

        // Taker: YES SELL at 50c with max fee (5% = 2.5 USDC)
        uint256 takerFeeAmount = 2_500_000;
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);

        // Maker: YES BUY at 50c
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        vm.pauseGasMetering();
        // Taker spent 100 YES, received 47.5 USDC (50 - 2.5 fee)
        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 47_500_000);
        // Maker spent 50 USDC, received 100 YES
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, yes, 100_000_000);
    }

    function test_MatchOrders_WithMaxFeeRate_Buy() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 52_500_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        // Taker: YES BUY at 50c with max fee (5% = 2.5 USDC)
        uint256 takerFeeAmount = 2_500_000;
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // Maker: YES SELL at 50c
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        vm.pauseGasMetering();
        // Taker spent 52.5 USDC, received 100 YES
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        // Maker spent 100 YES, received 50 USDC
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 50_000_000);
    }

    /// @notice Verify that exchange doesn't hold tokens after COMPLEMENTARY match (taker BUY)
    function test_MatchOrders_Complementary_NoExchangeBalance_TakerBuy() public {
        vm.pauseGasMetering();
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        // Taker: YES BUY
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        // Maker: YES SELL
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, makerFeeAmounts);

        vm.pauseGasMetering();
        // Exchange should hold no tokens after direct transfer COMPLEMENTARY match
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
        assertCTFBalance(address(exchange), no, 0);
    }

    function test_MatchOrders_Complementary_NoExchangeBalance_TakerSell() public {
        vm.pauseGasMetering();
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);

        // Taker: YES SELL
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);
        // Maker: YES BUY
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.resumeGasMetering();

        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, makerFeeAmounts);

        vm.pauseGasMetering();
        // Exchange should hold no tokens after COMPLEMENTARY match
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
        assertCTFBalance(address(exchange), no, 0);
        // Verify balances transferred correctly
        assertCollateralBalance(bob, 50_000_000);
        assertCTFBalance(carla, yes, 100_000_000);
    }

    function test_MatchOrders_revert_MismatchedTokenIds_MintSameTokenId() public {
        // Taker: BUY YES, Maker1: BUY YES (same token!), Maker2: BUY NO
        // Maker1 buying the same token as taker is invalid for MINT
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);
        dealUsdcAndApprove(dylanAddr, address(exchange), 50_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder1 = _createAndSignOrder(carlaPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder2 = _createAndSignOrder(dylanPK, no, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = makerOrder1;
        makerOrders[1] = makerOrder2;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 50_000_000;
        fillAmounts[1] = 50_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 0;
        makerFeeAmounts[1] = 0;

        vm.expectRevert(MismatchedTokenIds.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_revert_MismatchedTokenIds_InvalidTokenId() public {
        // Maker uses a tokenId from a different market — should be rejected
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);

        // Create a second condition with different tokenIds
        bytes32 otherConditionId = _prepareCondition(admin, hex"5678");

        // Compute a tokenId from the other market
        uint256 foreignTokenId = ctf.getPositionId(address(usdc), ctf.getCollectionId(bytes32(0), otherConditionId, 2));

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, foreignTokenId, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.expectRevert(MismatchedTokenIds.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_revert_MismatchedTokenIds_TokenIdZeroCollateralExtraction() public {
        // tokenId=0 represents collateral transfers and must never be accepted as a CTF outcome position.
        dealUsdcAndApprove(bob, address(exchange), 150_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 150_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, 0, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.expectRevert(MismatchedTokenIds.selector);
        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 150_000_000, fillAmounts, 0, makerFeeAmounts);
    }

    function test_MatchOrders_Events_Complementary_WithFees() public {
        dealUsdcAndApprove(bob, address(exchange), 52_500_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        bytes32 takerHash = exchange.hashOrder(takerOrder);
        bytes32 makerHash = exchange.hashOrder(makerOrder);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;
        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 100_000;

        vm.expectEmit(true, true, true, true);
        emit FeeCharged(feeReceiver, 100_000);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            makerHash, carla, bob, Side.SELL, yes, 100_000_000, 50_000_000, 100_000, bytes32(0), bytes32(0)
        );

        vm.expectEmit(true, true, true, true);
        emit FeeCharged(feeReceiver, 2_500_000);

        vm.expectEmit(true, true, true, true);
        emit OrderFilled(
            takerHash, bob, address(exchange), Side.BUY, yes, 50_000_000, 100_000_000, 2_500_000, bytes32(0), bytes32(0)
        );

        vm.expectEmit(true, true, true, true);
        emit OrdersMatched(takerHash, bob, Side.BUY, yes, 50_000_000, 100_000_000);

        vm.prank(admin);
        exchange.matchOrders(conditionId, takerOrder, makerOrders, 50_000_000, fillAmounts, 2_500_000, makerFeeAmounts);
    }
}
