// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { ExchangeInitParams, Order, Side, SignatureType } from "src/exchange/libraries/Structs.sol";
import { CTFExchange } from "src/exchange/CTFExchange.sol";
import { IConditionalTokens } from "src/exchange/interfaces/IConditionalTokens.sol";
import { ERC1155 } from "lib/solady/src/tokens/ERC1155.sol";
import { MockProxyFactory } from "./dev/mocks/MockProxyFactory.sol";
import { MockSafeFactory } from "./dev/mocks/MockSafeFactory.sol";

/// @notice Gas snapshot tests for Gnosis Safe wallet orders
/// @dev Tests complementary trades where makers use Safe wallets
contract GasSnapshotsSafe is BaseExchangeTest {
    address public bobSafe;
    address public carlaSafe;

    function setUp() public override {
        // Call parent setUp which deploys exchange
        super.setUp();

        // Re-deploy exchange with safe factory configured
        vm.startPrank(admin);
        ExchangeInitParams memory p = ExchangeInitParams({
            admin: admin,
            collateral: address(usdc),
            ctf: address(ctf),
            outcomeTokenFactory: address(ctf),
            proxyFactory: proxyFactory,
            safeFactory: safeFactory,
            feeReceiver: feeReceiver
        });

        exchange = new CTFExchange(p);
        exchange.addOperator(bob);
        exchange.addOperator(carla);

        // Deploy safe wallets for bob and carla
        bobSafe = MockSafeFactory(safeFactory).deploySafe(bob);
        carlaSafe = MockSafeFactory(safeFactory).deploySafe(carla);

        // Add safe wallets as operators
        exchange.addOperator(bobSafe);
        exchange.addOperator(carlaSafe);
        vm.stopPrank();
    }

    /*--------------------------------------------------------------
                   COMPLEMENTARY (BUY VS SELL) - SAFE
    --------------------------------------------------------------*/

    function test_GasSnapshotsSafe_complementary_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareSafeComplementary(1);

        vm.prank(admin);
        vm.startSnapshotGas("safe_complementary_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsSafe_complementary_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareSafeComplementary(5);

        vm.prank(admin);
        vm.startSnapshotGas("safe_complementary_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsSafe_complementary_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareSafeComplementary(10);

        vm.prank(admin);
        vm.startSnapshotGas("safe_complementary_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*--------------------------------------------------------------
                        MINT (BUY VS BUY) - SAFE
    --------------------------------------------------------------*/

    function test_GasSnapshotsSafe_mint_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareSafeMint(1);

        vm.prank(admin);
        vm.startSnapshotGas("safe_mint_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsSafe_mint_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareSafeMint(5);

        vm.prank(admin);
        vm.startSnapshotGas("safe_mint_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsSafe_mint_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareSafeMint(10);

        vm.prank(admin);
        vm.startSnapshotGas("safe_mint_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*--------------------------------------------------------------
                      MERGE (SELL VS SELL) - SAFE
    --------------------------------------------------------------*/

    function test_GasSnapshotsSafe_merge_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareSafeMerge(1);

        vm.prank(admin);
        vm.startSnapshotGas("safe_merge_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsSafe_merge_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareSafeMerge(5);

        vm.prank(admin);
        vm.startSnapshotGas("safe_merge_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsSafe_merge_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareSafeMerge(10);

        vm.prank(admin);
        vm.startSnapshotGas("safe_merge_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*--------------------------------------------------------------
                             SETUP HELPERS
    --------------------------------------------------------------*/

    function _prepareSafeComplementary(uint256 numMakers)
        internal
        returns (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        )
    {
        uint256 usdcPerMaker = 10_000_000;
        uint256 tokensPerMaker = 20_000_000;
        uint256 totalUsdc = usdcPerMaker * numMakers;
        uint256 totalTokens = tokensPerMaker * numMakers;

        // Fund safe wallets instead of EOAs
        _dealUsdcToSafe(bobSafe, totalUsdc);
        _dealOutcomeTokensToSafe(carlaSafe, yes, totalTokens);

        // Taker: bob's safe buys YES
        takerOrder = _createAndSignSafeOrder(bobPK, bobSafe, yes, totalUsdc, totalTokens, Side.BUY);
        makerOrders = new Order[](numMakers);
        fillAmounts = new uint256[](numMakers);
        feeAmounts = new uint256[](numMakers);

        // Makers: carla's safe sells YES
        for (uint256 i = 0; i < numMakers; i++) {
            makerOrders[i] = _createAndSignSafeOrderWithSalt(
                carlaPK, carlaSafe, yes, tokensPerMaker, usdcPerMaker, Side.SELL, i + 100
            );
            fillAmounts[i] = tokensPerMaker;
            feeAmounts[i] = 0;
        }

        takerFillAmount = totalUsdc;
    }

    function _prepareSafeMint(uint256 numMakers)
        internal
        returns (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        )
    {
        uint256 usdcPerMaker = 10_000_000;
        uint256 tokensPerMaker = 20_000_000;
        uint256 totalUsdc = usdcPerMaker * numMakers;
        uint256 totalTokens = tokensPerMaker * numMakers;
        uint256 takerUsdc = totalTokens / 2;

        // Fund safe wallets
        _dealUsdcToSafe(bobSafe, takerUsdc);
        _dealUsdcToSafe(carlaSafe, totalUsdc);

        // Taker: bob's safe buys YES
        takerOrder = _createAndSignSafeOrder(bobPK, bobSafe, yes, takerUsdc, totalTokens, Side.BUY);
        makerOrders = new Order[](numMakers);
        fillAmounts = new uint256[](numMakers);
        feeAmounts = new uint256[](numMakers);

        // Makers: carla's safe buys NO
        for (uint256 i = 0; i < numMakers; i++) {
            makerOrders[i] = _createAndSignSafeOrderWithSalt(
                carlaPK, carlaSafe, no, usdcPerMaker, tokensPerMaker, Side.BUY, i + 100
            );
            fillAmounts[i] = usdcPerMaker;
            feeAmounts[i] = 0;
        }

        takerFillAmount = takerUsdc;
    }

    function _prepareSafeMerge(uint256 numMakers)
        internal
        returns (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        )
    {
        uint256 tokensPerMaker = 20_000_000;
        uint256 usdcPerMaker = 10_000_000;
        uint256 totalTokens = tokensPerMaker * numMakers;
        uint256 totalUsdc = usdcPerMaker * numMakers;

        // Fund safe wallets with outcome tokens
        _dealOutcomeTokensToSafe(bobSafe, yes, totalTokens);
        _dealOutcomeTokensToSafe(carlaSafe, no, totalTokens);

        // Taker: bob's safe sells YES
        takerOrder = _createAndSignSafeOrder(bobPK, bobSafe, yes, totalTokens, totalUsdc, Side.SELL);
        makerOrders = new Order[](numMakers);
        fillAmounts = new uint256[](numMakers);
        feeAmounts = new uint256[](numMakers);

        // Makers: carla's safe sells NO
        for (uint256 i = 0; i < numMakers; i++) {
            makerOrders[i] = _createAndSignSafeOrderWithSalt(
                carlaPK, carlaSafe, no, tokensPerMaker, usdcPerMaker, Side.SELL, i + 100
            );
            fillAmounts[i] = tokensPerMaker;
            feeAmounts[i] = 0;
        }

        takerFillAmount = totalTokens;
    }

    /*--------------------------------------------------------------
                                HELPERS
    --------------------------------------------------------------*/

    function _createAndSignSafeOrder(
        uint256 signerPk,
        address safeWallet,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal view returns (Order memory order) {
        address signer = vm.addr(signerPk);
        order = _createOrder(safeWallet, tokenId, makerAmount, takerAmount, side);
        order.signer = signer;
        order.signatureType = SignatureType.POLY_GNOSIS_SAFE;
        order.signature = _signMessage(signerPk, exchange.hashOrder(order));
    }

    function _createAndSignSafeOrderWithSalt(
        uint256 signerPk,
        address safeWallet,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side,
        uint256 salt
    ) internal view returns (Order memory order) {
        order = _createAndSignSafeOrder(signerPk, safeWallet, tokenId, makerAmount, takerAmount, side);
        order.salt = salt;
        order.signature = _signMessage(signerPk, exchange.hashOrder(order));
    }

    function _dealUsdcToSafe(address safe, uint256 amount) internal {
        deal(address(usdc), safe, amount);
        vm.prank(safe);
        usdc.approve(address(exchange), type(uint256).max);
    }

    function _dealOutcomeTokensToSafe(address safe, uint256 tokenId, uint256 amount) internal {
        // Mint tokens via admin and transfer to safe
        vm.startPrank(admin);
        approve(address(usdc), address(ctf), type(uint256).max);
        deal(address(usdc), admin, amount);

        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        IConditionalTokens(ctf).splitPosition(address(usdc), bytes32(0), conditionId, partition, amount);
        ERC1155(address(ctf)).safeTransferFrom(admin, safe, tokenId, amount, "");
        vm.stopPrank();

        vm.prank(safe);
        ERC1155(address(ctf)).setApprovalForAll(address(exchange), true);
    }
}
