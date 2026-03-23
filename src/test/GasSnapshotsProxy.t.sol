// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { ExchangeInitParams, Order, Side, SignatureType } from "@ctf-exchange-v2/src/exchange/libraries/Structs.sol";
import { CTFExchange } from "@ctf-exchange-v2/src/exchange/CTFExchange.sol";
import { IConditionalTokens } from "@ctf-exchange-v2/src/exchange/interfaces/IConditionalTokens.sol";
import { ERC1155 } from "@solady/src/tokens/ERC1155.sol";
import { MockProxyFactory } from "./dev/mocks/MockProxyFactory.sol";
import { MockSafeFactory } from "./dev/mocks/MockSafeFactory.sol";

/// @notice Gas snapshot tests for proxy wallet orders
/// @dev Tests complementary trades where makers use proxy wallets
contract GasSnapshotsProxy is BaseExchangeTest {
    address public bobProxy;
    address public carlaProxy;

    function setUp() public override {
        // Call parent setUp which deploys exchange
        super.setUp();

        // Re-deploy exchange with proxy factory configured
        vm.startPrank(admin);
        ExchangeInitParams memory p = ExchangeInitParams({
            admin: admin,
            collateral: address(usdc),
            ctf: address(ctf),
            ctfCollateral: address(usdc),
            outcomeTokenFactory: address(ctf),
            proxyFactory: proxyFactory,
            safeFactory: safeFactory,
            feeReceiver: feeReceiver
        });

        exchange = new CTFExchange(p);
        exchange.addOperator(bob);
        exchange.addOperator(carla);

        // Deploy proxy wallets for bob and carla
        bobProxy = MockProxyFactory(proxyFactory).deployProxy(bob);
        carlaProxy = MockProxyFactory(proxyFactory).deployProxy(carla);

        // Add proxy wallets as operators
        exchange.addOperator(bobProxy);
        exchange.addOperator(carlaProxy);
        vm.stopPrank();
    }

    /*--------------------------------------------------------------
                  COMPLEMENTARY (BUY VS SELL) - PROXY
    --------------------------------------------------------------*/

    function test_GasSnapshotsProxy_complementary_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareProxyComplementary(1);

        vm.prank(admin);
        vm.startSnapshotGas("proxy_complementary_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsProxy_complementary_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareProxyComplementary(5);

        vm.prank(admin);
        vm.startSnapshotGas("proxy_complementary_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsProxy_complementary_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareProxyComplementary(10);

        vm.prank(admin);
        vm.startSnapshotGas("proxy_complementary_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*--------------------------------------------------------------
                       MINT (BUY VS BUY) - PROXY
    --------------------------------------------------------------*/

    function test_GasSnapshotsProxy_mint_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareProxyMint(1);

        vm.prank(admin);
        vm.startSnapshotGas("proxy_mint_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsProxy_mint_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareProxyMint(5);

        vm.prank(admin);
        vm.startSnapshotGas("proxy_mint_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsProxy_mint_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareProxyMint(10);

        vm.prank(admin);
        vm.startSnapshotGas("proxy_mint_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*--------------------------------------------------------------
                      MERGE (SELL VS SELL) - PROXY
    --------------------------------------------------------------*/

    function test_GasSnapshotsProxy_merge_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareProxyMerge(1);

        vm.prank(admin);
        vm.startSnapshotGas("proxy_merge_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsProxy_merge_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareProxyMerge(5);

        vm.prank(admin);
        vm.startSnapshotGas("proxy_merge_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsProxy_merge_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareProxyMerge(10);

        vm.prank(admin);
        vm.startSnapshotGas("proxy_merge_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*--------------------------------------------------------------
                             SETUP HELPERS
    --------------------------------------------------------------*/

    function _prepareProxyComplementary(uint256 numMakers)
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

        // Fund proxy wallets instead of EOAs
        _dealUsdcToProxy(bobProxy, totalUsdc);
        _dealOutcomeTokensToProxy(carlaProxy, yes, totalTokens);

        // Taker: bob's proxy buys YES
        takerOrder = _createAndSignProxyOrder(bobPK, bobProxy, yes, totalUsdc, totalTokens, Side.BUY);
        makerOrders = new Order[](numMakers);
        fillAmounts = new uint256[](numMakers);
        feeAmounts = new uint256[](numMakers);

        // Makers: carla's proxy sells YES
        for (uint256 i = 0; i < numMakers; i++) {
            makerOrders[i] = _createAndSignProxyOrderWithSalt(
                carlaPK, carlaProxy, yes, tokensPerMaker, usdcPerMaker, Side.SELL, i + 100
            );
            fillAmounts[i] = tokensPerMaker;
            feeAmounts[i] = 0;
        }

        takerFillAmount = totalUsdc;
    }

    function _prepareProxyMint(uint256 numMakers)
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

        // Fund proxy wallets
        _dealUsdcToProxy(bobProxy, takerUsdc);
        _dealUsdcToProxy(carlaProxy, totalUsdc);

        // Taker: bob's proxy buys YES
        takerOrder = _createAndSignProxyOrder(bobPK, bobProxy, yes, takerUsdc, totalTokens, Side.BUY);
        makerOrders = new Order[](numMakers);
        fillAmounts = new uint256[](numMakers);
        feeAmounts = new uint256[](numMakers);

        // Makers: carla's proxy buys NO
        for (uint256 i = 0; i < numMakers; i++) {
            makerOrders[i] = _createAndSignProxyOrderWithSalt(
                carlaPK, carlaProxy, no, usdcPerMaker, tokensPerMaker, Side.BUY, i + 100
            );
            fillAmounts[i] = usdcPerMaker;
            feeAmounts[i] = 0;
        }

        takerFillAmount = takerUsdc;
    }

    function _prepareProxyMerge(uint256 numMakers)
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

        // Fund proxy wallets with outcome tokens
        _dealOutcomeTokensToProxy(bobProxy, yes, totalTokens);
        _dealOutcomeTokensToProxy(carlaProxy, no, totalTokens);

        // Taker: bob's proxy sells YES
        takerOrder = _createAndSignProxyOrder(bobPK, bobProxy, yes, totalTokens, totalUsdc, Side.SELL);
        makerOrders = new Order[](numMakers);
        fillAmounts = new uint256[](numMakers);
        feeAmounts = new uint256[](numMakers);

        // Makers: carla's proxy sells NO
        for (uint256 i = 0; i < numMakers; i++) {
            makerOrders[i] = _createAndSignProxyOrderWithSalt(
                carlaPK, carlaProxy, no, tokensPerMaker, usdcPerMaker, Side.SELL, i + 100
            );
            fillAmounts[i] = tokensPerMaker;
            feeAmounts[i] = 0;
        }

        takerFillAmount = totalTokens;
    }

    /*--------------------------------------------------------------
                                HELPERS
    --------------------------------------------------------------*/

    function _createAndSignProxyOrder(
        uint256 signerPk,
        address proxyWallet,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal view returns (Order memory order) {
        address signer = vm.addr(signerPk);
        order = _createOrder(proxyWallet, tokenId, makerAmount, takerAmount, side);
        order.signer = signer;
        order.signatureType = SignatureType.POLY_PROXY;
        order.signature = _signMessage(signerPk, exchange.hashOrder(order));
    }

    function _createAndSignProxyOrderWithSalt(
        uint256 signerPk,
        address proxyWallet,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side,
        uint256 salt
    ) internal view returns (Order memory order) {
        order = _createAndSignProxyOrder(signerPk, proxyWallet, tokenId, makerAmount, takerAmount, side);
        order.salt = salt;
        order.signature = _signMessage(signerPk, exchange.hashOrder(order));
    }

    function _dealUsdcToProxy(address proxy, uint256 amount) internal {
        deal(address(usdc), proxy, amount);
        vm.prank(proxy);
        usdc.approve(address(exchange), type(uint256).max);
    }

    function _dealOutcomeTokensToProxy(address proxy, uint256 tokenId, uint256 amount) internal {
        // Mint tokens via admin and transfer to proxy
        vm.startPrank(admin);
        approve(address(usdc), address(ctf), type(uint256).max);
        deal(address(usdc), admin, amount);

        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        IConditionalTokens(ctf).splitPosition(address(usdc), bytes32(0), conditionId, partition, amount);
        ERC1155(address(ctf)).safeTransferFrom(admin, proxy, tokenId, amount, "");
        vm.stopPrank();

        vm.prank(proxy);
        ERC1155(address(ctf)).setApprovalForAll(address(exchange), true);
    }
}
