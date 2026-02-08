// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { Order, Side, ExchangeInitParams } from "src/exchange/libraries/Structs.sol";
import { ITradingEE } from "src/exchange/interfaces/ITrading.sol";
import { ERC1155 } from "lib/solady/src/tokens/ERC1155.sol";

import { CTFExchange } from "src/exchange/CTFExchange.sol";
import { CtfCollateralAdapterMock } from "./dev/mocks/CtfCollateralAdapterMock.sol";
import { USDC } from "./dev/mocks/USDC.sol";

contract MatchOrdersCtfCollateralAdapterTest is BaseExchangeTest {
    CtfCollateralAdapterMock public adapter;

    function setUp() public override {
        super.setUp();

        adapter = new CtfCollateralAdapterMock(address(ctf), address(usdc), address(usdc));
        vm.label(address(adapter), "CtfCollateralAdapterMock");

        vm.startPrank(admin);
        ExchangeInitParams memory p = ExchangeInitParams({
            admin: admin,
            collateral: address(usdc),
            ctf: address(ctf),
            outcomeTokenFactory: address(adapter),
            proxyFactory: address(0),
            safeFactory: address(0),
            feeReceiver: feeReceiver
        });

        exchange = new CTFExchange(p);
        exchange.addOperator(bob);
        exchange.addOperator(carla);
        vm.stopPrank();
    }

    function test_MatchOrders_Mint_WithCtfCollateralAdapter() public {
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, no, 100_000_000);
    }

    function test_MatchOrders_Complementary_WithCtfCollateralAdapter() public {
        dealUsdcAndApprove(bob, address(exchange), 50_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 50_000_000);
    }

    function test_MatchOrders_Complementary_Fees_WithCtfCollateralAdapter() public {
        uint256 takerFeeAmount = 2_500_000;
        uint256 makerFeeAmount = 100_000;

        dealUsdcAndApprove(bob, address(exchange), 50_000_000 + takerFeeAmount);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 50_000_000 - makerFeeAmount);
        assertCollateralBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrders_Merge_WithCtfCollateralAdapter() public {
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 50_000_000);
        assertCTFBalance(carla, no, 0);
        assertCollateralBalance(carla, 50_000_000);
    }

    function test_MatchOrders_Merge_Fees_WithCtfCollateralAdapter() public {
        uint256 takerFeeAmount = 1_000_000;
        uint256 makerFeeAmount = 500_000;

        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 50_000_000 - takerFeeAmount);
        assertCTFBalance(carla, no, 0);
        assertCollateralBalance(carla, 50_000_000 - makerFeeAmount);
        assertCollateralBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrders_Merge_Reverts_WhenAdapterNotApproved() public {
        vm.prank(address(exchange));
        ERC1155(address(ctf)).setApprovalForAll(address(adapter), false);

        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.expectRevert();
        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );
    }

    function test_MatchOrders_Mint_Reverts_WhenAdapterUsdceMismatch() public {
        USDC other = new USDC();
        CtfCollateralAdapterMock badAdapter = new CtfCollateralAdapterMock(address(ctf), address(usdc), address(other));

        vm.startPrank(admin);
        ExchangeInitParams memory p = ExchangeInitParams({
            admin: admin,
            collateral: address(usdc),
            ctf: address(ctf),
            outcomeTokenFactory: address(badAdapter),
            proxyFactory: address(0),
            safeFactory: address(0),
            feeReceiver: feeReceiver
        });

        CTFExchange badExchange = new CTFExchange(p);
        badExchange.addOperator(bob);
        badExchange.addOperator(carla);
        vm.stopPrank();

        other.mint(address(badAdapter), 100_000_000);

        dealUsdcAndApprove(bob, address(badExchange), 50_000_000);
        dealUsdcAndApprove(carla, address(badExchange), 50_000_000);

        Order memory takerOrder = _createOrder(bob, yes, 50_000_000, 100_000_000, Side.BUY);
        takerOrder.signature = _signMessage(bobPK, badExchange.hashOrder(takerOrder));
        Order memory makerOrder = _createOrder(carla, no, 50_000_000, 100_000_000, Side.BUY);
        makerOrder.signature = _signMessage(carlaPK, badExchange.hashOrder(makerOrder));

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.expectRevert(ITradingEE.TooLittleTokensReceived.selector);
        vm.prank(admin);
        badExchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );
    }

    function test_MatchOrders_Mint_Fees_WithCtfCollateralAdapter() public {
        uint256 takerFeeAmount = 2_500_000;
        uint256 makerFeeAmount = 100_000;

        dealUsdcAndApprove(bob, address(exchange), 50_000_000 + takerFeeAmount);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000 + makerFeeAmount);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, no, 100_000_000);
        assertCollateralBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }
}
