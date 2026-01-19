// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { Order, Side } from "src/exchange/libraries/Structs.sol";

/// @notice Gas snapshot tests for matchOrders
/// @dev Run with: forge test --match-contract GasSnapshots_Test --gas-report
/// @dev Snapshots are written to snapshots/GasSnapshots_Test.json
contract GasSnapshots_Test is BaseExchangeTest {

    /*//////////////////////////////////////////////////////////////
                        COMPLEMENTARY (BUY vs SELL)
    //////////////////////////////////////////////////////////////*/

    function test_complementary_1maker() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareComplementary(1);

        vm.prank(admin);
        vm.startSnapshotGas("complementary_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_complementary_5makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareComplementary(5);

        vm.prank(admin);
        vm.startSnapshotGas("complementary_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_complementary_10makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareComplementary(10);

        vm.prank(admin);
        vm.startSnapshotGas("complementary_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_complementary_20makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareComplementary(20);

        vm.prank(admin);
        vm.startSnapshotGas("complementary_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                            MINT (BUY vs BUY)
    //////////////////////////////////////////////////////////////*/

    function test_mint_1maker() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareMint(1);

        vm.prank(admin);
        vm.startSnapshotGas("mint_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_mint_5makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareMint(5);

        vm.prank(admin);
        vm.startSnapshotGas("mint_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_mint_10makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareMint(10);

        vm.prank(admin);
        vm.startSnapshotGas("mint_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_mint_20makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareMint(20);

        vm.prank(admin);
        vm.startSnapshotGas("mint_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                          MERGE (SELL vs SELL)
    //////////////////////////////////////////////////////////////*/

    function test_merge_1maker() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareMerge(1);

        vm.prank(admin);
        vm.startSnapshotGas("merge_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_merge_5makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareMerge(5);

        vm.prank(admin);
        vm.startSnapshotGas("merge_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_merge_10makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareMerge(10);

        vm.prank(admin);
        vm.startSnapshotGas("merge_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_merge_20makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareMerge(20);

        vm.prank(admin);
        vm.startSnapshotGas("merge_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                    COMBO: COMPLEMENTARY + MINT
                (Taker BUY YES, half SELL YES + half BUY NO)
    //////////////////////////////////////////////////////////////*/

    function test_combo_complementary_mint_10makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareComboComplementaryMint(10);

        vm.prank(admin);
        vm.startSnapshotGas("combo_complementary_mint_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_combo_complementary_mint_20makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareComboComplementaryMint(20);

        vm.prank(admin);
        vm.startSnapshotGas("combo_complementary_mint_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                    COMBO: COMPLEMENTARY + MERGE
                (Taker SELL YES, half BUY YES + half SELL NO)
    //////////////////////////////////////////////////////////////*/

    function test_combo_complementary_merge_10makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareComboComplementaryMerge(10);

        vm.prank(admin);
        vm.startSnapshotGas("combo_complementary_merge_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_combo_complementary_merge_20makers() public {
        (Order memory takerOrder, Order[] memory makerOrders, uint256 takerFillAmount, uint256[] memory fillAmounts, uint256[] memory feeAmounts) = _prepareComboComplementaryMerge(20);

        vm.prank(admin);
        vm.startSnapshotGas("combo_complementary_merge_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                              SETUP HELPERS
    //////////////////////////////////////////////////////////////*/

    function _prepareComplementary(uint256 numMakers) internal returns (
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory fillAmounts,
        uint256[] memory feeAmounts
    ) {
        uint256 usdcPerMaker = 10_000_000;
        uint256 tokensPerMaker = 20_000_000;
        uint256 totalUsdc = usdcPerMaker * numMakers;
        uint256 totalTokens = tokensPerMaker * numMakers;

        dealUsdcAndApprove(bob, address(exchange), totalUsdc);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, totalTokens);

        takerOrder = _createAndSignOrder(bobPK, yes, totalUsdc, totalTokens, Side.BUY);
        makerOrders = new Order[](numMakers);
        fillAmounts = new uint256[](numMakers);
        feeAmounts = new uint256[](numMakers);

        for (uint256 i = 0; i < numMakers; i++) {
            makerOrders[i] = _createAndSignOrderWithSalt(carlaPK, yes, tokensPerMaker, usdcPerMaker, Side.SELL, i + 100);
            fillAmounts[i] = tokensPerMaker;
            feeAmounts[i] = 0;
        }

        takerFillAmount = totalUsdc;
    }

    function _prepareMint(uint256 numMakers) internal returns (
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory fillAmounts,
        uint256[] memory feeAmounts
    ) {
        uint256 usdcPerMaker = 10_000_000;
        uint256 tokensPerMaker = 20_000_000;
        uint256 totalUsdc = usdcPerMaker * numMakers;
        uint256 totalTokens = tokensPerMaker * numMakers;
        uint256 takerUsdc = totalTokens / 2;

        dealUsdcAndApprove(bob, address(exchange), takerUsdc);
        dealUsdcAndApprove(carla, address(exchange), totalUsdc);

        takerOrder = _createAndSignOrder(bobPK, yes, takerUsdc, totalTokens, Side.BUY);
        makerOrders = new Order[](numMakers);
        fillAmounts = new uint256[](numMakers);
        feeAmounts = new uint256[](numMakers);

        for (uint256 i = 0; i < numMakers; i++) {
            makerOrders[i] = _createAndSignOrderWithSalt(carlaPK, no, usdcPerMaker, tokensPerMaker, Side.BUY, i + 100);
            fillAmounts[i] = usdcPerMaker;
            feeAmounts[i] = 0;
        }

        takerFillAmount = takerUsdc;
    }

    function _prepareMerge(uint256 numMakers) internal returns (
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory fillAmounts,
        uint256[] memory feeAmounts
    ) {
        uint256 tokensPerMaker = 20_000_000;
        uint256 usdcPerMaker = 10_000_000;
        uint256 totalTokens = tokensPerMaker * numMakers;
        uint256 totalUsdc = usdcPerMaker * numMakers;

        dealOutcomeTokensAndApprove(bob, address(exchange), yes, totalTokens);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, totalTokens);

        takerOrder = _createAndSignOrder(bobPK, yes, totalTokens, totalUsdc, Side.SELL);
        makerOrders = new Order[](numMakers);
        fillAmounts = new uint256[](numMakers);
        feeAmounts = new uint256[](numMakers);

        for (uint256 i = 0; i < numMakers; i++) {
            makerOrders[i] = _createAndSignOrderWithSalt(carlaPK, no, tokensPerMaker, usdcPerMaker, Side.SELL, i + 100);
            fillAmounts[i] = tokensPerMaker;
            feeAmounts[i] = 0;
        }

        takerFillAmount = totalTokens;
    }

    /// @notice Combo: Taker BUY YES, half makers SELL YES (complementary), half makers BUY NO (mint)
    function _prepareComboComplementaryMint(uint256 numMakers) internal returns (
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory fillAmounts,
        uint256[] memory feeAmounts
    ) {
        uint256 half = numMakers / 2;
        uint256 usdcPerMaker = 10_000_000;
        uint256 tokensPerMaker = 20_000_000;

        // Taker needs USDC for both complementary and mint portions
        uint256 totalTakerUsdc = usdcPerMaker * half + (tokensPerMaker * half / 2);
        uint256 totalTakerTokens = tokensPerMaker * numMakers;

        dealUsdcAndApprove(bob, address(exchange), totalTakerUsdc);
        // Carla needs YES tokens for complementary (SELL) and USDC for mint (BUY)
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, tokensPerMaker * half);
        dealUsdcAndApprove(carla, address(exchange), usdcPerMaker * half);

        takerOrder = _createAndSignOrder(bobPK, yes, totalTakerUsdc, totalTakerTokens, Side.BUY);
        makerOrders = new Order[](numMakers);
        fillAmounts = new uint256[](numMakers);
        feeAmounts = new uint256[](numMakers);

        // First half: complementary (SELL YES)
        for (uint256 i = 0; i < half; i++) {
            makerOrders[i] = _createAndSignOrderWithSalt(carlaPK, yes, tokensPerMaker, usdcPerMaker, Side.SELL, i + 100);
            fillAmounts[i] = tokensPerMaker;
            feeAmounts[i] = 0;
        }

        // Second half: mint (BUY NO)
        for (uint256 i = half; i < numMakers; i++) {
            makerOrders[i] = _createAndSignOrderWithSalt(carlaPK, no, usdcPerMaker, tokensPerMaker, Side.BUY, i + 100);
            fillAmounts[i] = usdcPerMaker;
            feeAmounts[i] = 0;
        }

        takerFillAmount = totalTakerUsdc;
    }

    /// @notice Combo: Taker SELL YES, half makers BUY YES (complementary), half makers SELL NO (merge)
    function _prepareComboComplementaryMerge(uint256 numMakers) internal returns (
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory fillAmounts,
        uint256[] memory feeAmounts
    ) {
        uint256 half = numMakers / 2;
        uint256 tokensPerMaker = 20_000_000;
        uint256 usdcPerMaker = 10_000_000;

        uint256 totalTakerTokens = tokensPerMaker * numMakers;
        // Taker receives USDC from complementary and merge
        uint256 totalTakerUsdc = usdcPerMaker * half + usdcPerMaker * half;

        dealOutcomeTokensAndApprove(bob, address(exchange), yes, totalTakerTokens);
        // Carla needs USDC for complementary (BUY) and NO tokens for merge (SELL)
        dealUsdcAndApprove(carla, address(exchange), usdcPerMaker * half);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, tokensPerMaker * half);

        takerOrder = _createAndSignOrder(bobPK, yes, totalTakerTokens, totalTakerUsdc, Side.SELL);
        makerOrders = new Order[](numMakers);
        fillAmounts = new uint256[](numMakers);
        feeAmounts = new uint256[](numMakers);

        // First half: complementary (BUY YES)
        for (uint256 i = 0; i < half; i++) {
            makerOrders[i] = _createAndSignOrderWithSalt(carlaPK, yes, usdcPerMaker, tokensPerMaker, Side.BUY, i + 100);
            fillAmounts[i] = usdcPerMaker;
            feeAmounts[i] = 0;
        }

        // Second half: merge (SELL NO)
        for (uint256 i = half; i < numMakers; i++) {
            makerOrders[i] = _createAndSignOrderWithSalt(carlaPK, no, tokensPerMaker, usdcPerMaker, Side.SELL, i + 100);
            fillAmounts[i] = tokensPerMaker;
            feeAmounts[i] = 0;
        }

        takerFillAmount = totalTakerTokens;
    }

    /*//////////////////////////////////////////////////////////////
                              HELPERS
    //////////////////////////////////////////////////////////////*/

    function _createAndSignOrderWithSalt(
        uint256 pk,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side,
        uint256 salt
    ) internal view returns (Order memory) {
        address maker = vm.addr(pk);
        Order memory order = _createOrder(maker, tokenId, makerAmount, takerAmount, side);
        order.salt = salt;
        order.signature = _signMessage(pk, exchange.hashOrder(order));
        return order;
    }
}
