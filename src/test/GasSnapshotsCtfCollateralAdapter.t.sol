// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { ExchangeInitParams, Order, Side } from "src/exchange/libraries/Structs.sol";
import { CTFExchange } from "src/exchange/CTFExchange.sol";
import { ERC1155 } from "lib/solady/src/tokens/ERC1155.sol";
import { IConditionalTokens } from "src/exchange/interfaces/IConditionalTokens.sol";
import { CTFHelpers } from "src/adapters/libraries/CTFHelpers.sol";
import { CtfCollateralAdapter } from "src/adapters/CtfCollateralAdapter.sol";
import { Collateral, CollateralSetup } from "src/test/dev/CollateralSetup.sol";
import { USDCe } from "src/test/dev/mocks/USDCe.sol";
import { MockProxyFactory } from "./dev/mocks/MockProxyFactory.sol";
import { MockSafeFactory } from "./dev/mocks/MockSafeFactory.sol";

/// @notice Gas snapshot tests for matchOrders using real CtfCollateralAdapter
/// @dev Run with: forge test --match-contract GasSnapshotsCtfCollateralAdapter --gas-report
contract GasSnapshotsCtfCollateralAdapter is BaseExchangeTest {
    CtfCollateralAdapter public adapter;

    Collateral collateral;
    USDCe usdce;

    function setUp() public override {
        super.setUp();

        // 1. Deploy CollateralToken system
        collateral = CollateralSetup._deploy(admin);
        usdce = collateral.usdce;

        // 2. Deploy real CtfCollateralAdapter
        adapter = new CtfCollateralAdapter(address(ctf), address(collateral.token), address(usdce));
        vm.label(address(adapter), "CtfCollateralAdapter");

        // 3. Grant Router role on CollateralToken to the adapter
        vm.prank(admin);
        collateral.token.addRouter(address(adapter));

        // 4. Recompute yes/no using usdce (CtfCollateralAdapter uses usdce for position IDs)
        uint256[] memory positionIds = CTFHelpers.positionIds(address(usdce), conditionId);
        yes = positionIds[0];
        no = positionIds[1];

        // 5. Create new CTFExchange with collateral: collateralToken, outcomeTokenFactory: adapter
        MockProxyFactory mockProxyFactory = new MockProxyFactory();
        MockSafeFactory mockSafeFactory = new MockSafeFactory();

        vm.startPrank(admin);
        ExchangeInitParams memory p = ExchangeInitParams({
            admin: admin,
            collateral: address(collateral.token),
            ctf: address(ctf),
            outcomeTokenFactory: address(adapter),
            proxyFactory: address(mockProxyFactory),
            safeFactory: address(mockSafeFactory),
            feeReceiver: feeReceiver
        });

        exchange = new CTFExchange(p);
        exchange.addOperator(bob);
        exchange.addOperator(carla);
        vm.stopPrank();
    }

    /*--------------------------------------------------------------
                      COMPLEMENTARY (BUY VS SELL)
    --------------------------------------------------------------*/

    function test_GasSnapshotsCtfCollateralAdapter_complementary_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComplementary(1);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_complementary_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsCtfCollateralAdapter_complementary_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComplementary(5);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_complementary_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsCtfCollateralAdapter_complementary_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComplementary(10);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_complementary_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*--------------------------------------------------------------
                           MINT (BUY VS BUY)
    --------------------------------------------------------------*/

    function test_GasSnapshotsCtfCollateralAdapter_mint_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMint(1);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_mint_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsCtfCollateralAdapter_mint_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMint(5);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_mint_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsCtfCollateralAdapter_mint_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMint(10);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_mint_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*--------------------------------------------------------------
                          MERGE (SELL VS SELL)
    --------------------------------------------------------------*/

    function test_GasSnapshotsCtfCollateralAdapter_merge_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMerge(1);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_merge_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsCtfCollateralAdapter_merge_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMerge(5);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_merge_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsCtfCollateralAdapter_merge_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMerge(10);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_merge_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*--------------------------------------------------------------
                      COMBO: COMPLEMENTARY + MINT
    --------------------------------------------------------------*/

    function test_GasSnapshotsCtfCollateralAdapter_combo_complementary_mint_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMint(10);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_combo_complementary_mint_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsCtfCollateralAdapter_combo_complementary_mint_20makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMint(20);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_combo_complementary_mint_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*--------------------------------------------------------------
                      COMBO: COMPLEMENTARY + MERGE
    --------------------------------------------------------------*/

    function test_GasSnapshotsCtfCollateralAdapter_combo_complementary_merge_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMerge(10);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_combo_complementary_merge_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_GasSnapshotsCtfCollateralAdapter_combo_complementary_merge_20makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMerge(20);

        vm.prank(admin);
        vm.startSnapshotGas("ctf_collateral_adapter_combo_complementary_merge_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*--------------------------------------------------------------
                            HELPER FUNCTIONS
    --------------------------------------------------------------*/

    function _dealCollateralAndApprove(address to, address spender, uint256 amount) internal {
        usdce.mint(to, amount);
        vm.startPrank(to);
        usdce.approve(address(collateral.onramp), amount);
        collateral.onramp.wrap(address(usdce), to, amount);
        collateral.token.approve(spender, amount);
        vm.stopPrank();
    }

    function _dealOutcomeTokensAndApprove(address to, address spender, uint256 tokenId, uint256 amount) internal {
        usdce.mint(admin, amount);

        vm.startPrank(admin);
        usdce.approve(address(ctf), type(uint256).max);
        IConditionalTokens(ctf).splitPosition(address(usdce), bytes32(0), conditionId, CTFHelpers.partition(), amount);
        ERC1155(address(ctf)).safeTransferFrom(admin, to, tokenId, amount, "");
        vm.stopPrank();

        vm.prank(to);
        ERC1155(address(ctf)).setApprovalForAll(spender, true);
    }

    function _prepareComplementary(uint256 numMakers)
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

        _dealCollateralAndApprove(bob, address(exchange), totalUsdc);
        _dealOutcomeTokensAndApprove(carla, address(exchange), yes, totalTokens);

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

    function _prepareMint(uint256 numMakers)
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

        _dealCollateralAndApprove(bob, address(exchange), takerUsdc);
        _dealCollateralAndApprove(carla, address(exchange), totalUsdc);

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

    function _prepareMerge(uint256 numMakers)
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

        _dealOutcomeTokensAndApprove(bob, address(exchange), yes, totalTokens);
        _dealOutcomeTokensAndApprove(carla, address(exchange), no, totalTokens);

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
    function _prepareComboComplementaryMint(uint256 numMakers)
        internal
        returns (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        )
    {
        uint256 half = numMakers / 2;
        uint256 usdcPerMaker = 10_000_000;
        uint256 tokensPerMaker = 20_000_000;

        // Taker needs collateral for both complementary and mint portions
        uint256 totalTakerUsdc = usdcPerMaker * half + (tokensPerMaker * half / 2);
        uint256 totalTakerTokens = tokensPerMaker * numMakers;

        _dealCollateralAndApprove(bob, address(exchange), totalTakerUsdc);
        // Carla needs YES tokens for complementary (SELL) and collateral for mint (BUY)
        _dealOutcomeTokensAndApprove(carla, address(exchange), yes, tokensPerMaker * half);
        _dealCollateralAndApprove(carla, address(exchange), usdcPerMaker * half);

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
    function _prepareComboComplementaryMerge(uint256 numMakers)
        internal
        returns (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        )
    {
        uint256 half = numMakers / 2;
        uint256 tokensPerMaker = 20_000_000;
        uint256 usdcPerMaker = 10_000_000;

        uint256 totalTakerTokens = tokensPerMaker * numMakers;
        // Taker receives collateral from complementary and merge
        uint256 totalTakerUsdc = usdcPerMaker * half + usdcPerMaker * half;

        _dealOutcomeTokensAndApprove(bob, address(exchange), yes, totalTakerTokens);
        // Carla needs collateral for complementary (BUY) and NO tokens for merge (SELL)
        _dealCollateralAndApprove(carla, address(exchange), usdcPerMaker * half);
        _dealOutcomeTokensAndApprove(carla, address(exchange), no, tokensPerMaker * half);

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
