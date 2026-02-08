// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { ExchangeInitParams, Order, Side, SignatureType } from "src/exchange/libraries/Structs.sol";
import { PolyProxyLib } from "src/exchange/libraries/PolyProxyLib.sol";
import { PolySafeLib } from "src/exchange/libraries/PolySafeLib.sol";
import { CTFExchange } from "src/exchange/CTFExchange.sol";
import { IConditionalTokens } from "src/exchange/interfaces/IConditionalTokens.sol";
import { ERC1155 } from "lib/solady/src/tokens/ERC1155.sol";
import { CtfCollateralAdapterMock } from "./dev/mocks/CtfCollateralAdapterMock.sol";

/// @notice Gas snapshot tests for matchOrders
/// @dev Run with: forge test --match-contract GasSnapshots_Test --gas-report
/// @dev Snapshots are written to snapshots/GasSnapshots_Test.json
contract GasSnapshots_Test is BaseExchangeTest {
    /*//////////////////////////////////////////////////////////////
                        COMPLEMENTARY (BUY vs SELL)
    //////////////////////////////////////////////////////////////*/

    function test_complementary_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComplementary(1);

        vm.prank(admin);
        vm.startSnapshotGas("complementary_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_complementary_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComplementary(5);

        vm.prank(admin);
        vm.startSnapshotGas("complementary_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_complementary_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComplementary(10);

        vm.prank(admin);
        vm.startSnapshotGas("complementary_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_complementary_20makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComplementary(20);

        vm.prank(admin);
        vm.startSnapshotGas("complementary_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                            MINT (BUY vs BUY)
    //////////////////////////////////////////////////////////////*/

    function test_mint_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMint(1);

        vm.prank(admin);
        vm.startSnapshotGas("mint_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_mint_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMint(5);

        vm.prank(admin);
        vm.startSnapshotGas("mint_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_mint_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMint(10);

        vm.prank(admin);
        vm.startSnapshotGas("mint_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_mint_20makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMint(20);

        vm.prank(admin);
        vm.startSnapshotGas("mint_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                          MERGE (SELL vs SELL)
    //////////////////////////////////////////////////////////////*/

    function test_merge_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMerge(1);

        vm.prank(admin);
        vm.startSnapshotGas("merge_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_merge_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMerge(5);

        vm.prank(admin);
        vm.startSnapshotGas("merge_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_merge_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMerge(10);

        vm.prank(admin);
        vm.startSnapshotGas("merge_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_merge_20makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMerge(20);

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
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMint(10);

        vm.prank(admin);
        vm.startSnapshotGas("combo_complementary_mint_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_combo_complementary_mint_20makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMint(20);

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
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMerge(10);

        vm.prank(admin);
        vm.startSnapshotGas("combo_complementary_merge_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_combo_complementary_merge_20makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMerge(20);

        vm.prank(admin);
        vm.startSnapshotGas("combo_complementary_merge_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                              SETUP HELPERS
    //////////////////////////////////////////////////////////////*/

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

/*//////////////////////////////////////////////////////////////
                    MOCK FACTORIES FOR WALLET TESTS
//////////////////////////////////////////////////////////////*/

/// @notice Mock implementation for proxy wallets (supports ERC1155 receiver)
contract MockProxyImplementation {
    function cloneConstructor(bytes memory) external { }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    }
}

/// @notice Mock proxy factory that implements getImplementation()
contract MockProxyFactory {
    address public immutable impl;

    constructor() {
        impl = address(new MockProxyImplementation());
    }

    function getImplementation() external view returns (address) {
        return impl;
    }

    /// @dev Called by proxy during deployment initialization
    function cloneConstructor(bytes memory) external { }

    function deployProxy(address signer) external returns (address proxy) {
        bytes memory creationCode = _computeCreationCode(address(this), impl);
        bytes32 salt = keccak256(abi.encodePacked(signer));
        assembly {
            proxy := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        require(proxy != address(0), "deployment failed");
    }

    /// @dev Copy of PolyProxyLib._computeCreationCode for test use
    function _computeCreationCode(address deployer, address target) internal pure returns (bytes memory clone) {
        bytes memory consData = abi.encodeWithSignature("cloneConstructor(bytes)", new bytes(0));
        bytes memory buffer = new bytes(99);
        assembly {
            mstore(add(buffer, 0x20), 0x3d3d606380380380913d393d73bebebebebebebebebebebebebebebebebebebe)
            mstore(add(buffer, 0x2d), mul(deployer, 0x01000000000000000000000000))
            mstore(add(buffer, 0x41), 0x5af4602a57600080fd5b602d8060366000396000f3363d3d373d3d3d363d73be)
            mstore(add(buffer, 0x60), mul(target, 0x01000000000000000000000000))
            mstore(add(buffer, 116), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        }
        clone = abi.encodePacked(buffer, consData);
    }
}

/// @notice Mock implementation for safe wallets (supports ERC1155 receiver)
contract MockSafeImplementation {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return 0xbc197c81;
    }
}

/// @notice Mock safe factory that implements masterCopy()
contract MockSafeFactory {
    address public immutable impl;

    bytes private constant proxyCreationCode =
        hex"608060405234801561001057600080fd5b5060405161017138038061017183398101604081905261002f916100b9565b6001600160a01b0381166100945760405162461bcd60e51b815260206004820152602260248201527f496e76616c69642073696e676c65746f6e20616464726573732070726f766964604482015261195960f21b606482015260840160405180910390fd5b600080546001600160a01b0319166001600160a01b03929092169190911790556100e7565b6000602082840312156100ca578081fd5b81516001600160a01b03811681146100e0578182fd5b9392505050565b607c806100f56000396000f3fe6080604052600080546001600160a01b0316813563530ca43760e11b1415602857808252602082f35b3682833781823684845af490503d82833e806041573d82fd5b503d81f3fea264697066735822122015938e3bf2c49f5df5c1b7f9569fa85cc5d6f3074bb258a2dc0c7e299bc9e33664736f6c63430008040033";

    constructor() {
        impl = address(new MockSafeImplementation());
    }

    function masterCopy() external view returns (address) {
        return impl;
    }

    function deploySafe(address signer) external returns (address safe) {
        bytes memory creationCode = abi.encodePacked(proxyCreationCode, abi.encode(impl));
        bytes32 salt = keccak256(abi.encode(signer));
        assembly {
            safe := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        require(safe != address(0), "deployment failed");
    }
}

/*//////////////////////////////////////////////////////////////
                    PROXY WALLET GAS SNAPSHOTS
//////////////////////////////////////////////////////////////*/

/// @notice Gas snapshot tests for proxy wallet orders
/// @dev Tests complementary trades where makers use proxy wallets
contract GasSnapshotsProxy_Test is BaseExchangeTest {
    MockProxyFactory public proxyFactory;
    address public bobProxy;
    address public carlaProxy;

    function setUp() public override {
        // Deploy factories first
        proxyFactory = new MockProxyFactory();

        // Call parent setUp which deploys exchange
        super.setUp();

        // Re-deploy exchange with proxy factory configured
        vm.startPrank(admin);
        ExchangeInitParams memory p = ExchangeInitParams({
            admin: admin,
            collateral: address(usdc),
            ctf: address(ctf),
            outcomeTokenFactory: address(ctf),
            proxyFactory: address(proxyFactory),
            safeFactory: address(0),
            feeReceiver: feeReceiver
        });

        exchange = new CTFExchange(p);
        exchange.addOperator(bob);
        exchange.addOperator(carla);

        // Deploy proxy wallets for bob and carla
        bobProxy = proxyFactory.deployProxy(bob);
        carlaProxy = proxyFactory.deployProxy(carla);

        // Add proxy wallets as operators
        exchange.addOperator(bobProxy);
        exchange.addOperator(carlaProxy);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        COMPLEMENTARY (BUY vs SELL) - PROXY
    //////////////////////////////////////////////////////////////*/

    function test_proxy_complementary_1maker() public {
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

    function test_proxy_complementary_5makers() public {
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

    function test_proxy_complementary_10makers() public {
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

    /*//////////////////////////////////////////////////////////////
                            MINT (BUY vs BUY) - PROXY
    //////////////////////////////////////////////////////////////*/

    function test_proxy_mint_1maker() public {
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

    function test_proxy_mint_5makers() public {
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

    function test_proxy_mint_10makers() public {
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

    /*//////////////////////////////////////////////////////////////
                          MERGE (SELL vs SELL) - PROXY
    //////////////////////////////////////////////////////////////*/

    function test_proxy_merge_1maker() public {
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

    function test_proxy_merge_5makers() public {
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

    function test_proxy_merge_10makers() public {
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

    /*//////////////////////////////////////////////////////////////
                              SETUP HELPERS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                              HELPERS
    //////////////////////////////////////////////////////////////*/

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

/*//////////////////////////////////////////////////////////////
                    SAFE WALLET GAS SNAPSHOTS
//////////////////////////////////////////////////////////////*/

/// @notice Gas snapshot tests for Gnosis Safe wallet orders
/// @dev Tests complementary trades where makers use Safe wallets
contract GasSnapshotsSafe_Test is BaseExchangeTest {
    MockSafeFactory public safeFactory;
    address public bobSafe;
    address public carlaSafe;

    function setUp() public override {
        // Deploy factories first
        safeFactory = new MockSafeFactory();

        // Call parent setUp which deploys exchange
        super.setUp();

        // Re-deploy exchange with safe factory configured
        vm.startPrank(admin);
        ExchangeInitParams memory p = ExchangeInitParams({
            admin: admin,
            collateral: address(usdc),
            ctf: address(ctf),
            outcomeTokenFactory: address(ctf),
            proxyFactory: address(0),
            safeFactory: address(safeFactory),
            feeReceiver: feeReceiver
        });

        exchange = new CTFExchange(p);
        exchange.addOperator(bob);
        exchange.addOperator(carla);

        // Deploy safe wallets for bob and carla
        bobSafe = safeFactory.deploySafe(bob);
        carlaSafe = safeFactory.deploySafe(carla);

        // Add safe wallets as operators
        exchange.addOperator(bobSafe);
        exchange.addOperator(carlaSafe);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        COMPLEMENTARY (BUY vs SELL) - SAFE
    //////////////////////////////////////////////////////////////*/

    function test_safe_complementary_1maker() public {
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

    function test_safe_complementary_5makers() public {
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

    function test_safe_complementary_10makers() public {
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

    /*//////////////////////////////////////////////////////////////
                            MINT (BUY vs BUY) - SAFE
    //////////////////////////////////////////////////////////////*/

    function test_safe_mint_1maker() public {
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

    function test_safe_mint_5makers() public {
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

    function test_safe_mint_10makers() public {
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

    /*//////////////////////////////////////////////////////////////
                          MERGE (SELL vs SELL) - SAFE
    //////////////////////////////////////////////////////////////*/

    function test_safe_merge_1maker() public {
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

    function test_safe_merge_5makers() public {
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

    function test_safe_merge_10makers() public {
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

    /*//////////////////////////////////////////////////////////////
                              SETUP HELPERS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                              HELPERS
    //////////////////////////////////////////////////////////////*/

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

/// @notice Gas snapshot tests for matchOrders using CTF Collateral Adapter
/// @dev Run with: forge test --match-contract GasSnapshotsCtfAdapter_Test --gas-report
contract GasSnapshotsCtfAdapter_Test is BaseExchangeTest {
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

    /*//////////////////////////////////////////////////////////////
                        COMPLEMENTARY (BUY vs SELL)
    //////////////////////////////////////////////////////////////*/

    function test_ctfadapter_complementary_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComplementary(1);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_complementary_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_ctfadapter_complementary_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComplementary(5);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_complementary_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_ctfadapter_complementary_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComplementary(10);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_complementary_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                            MINT (BUY vs BUY)
    //////////////////////////////////////////////////////////////*/

    function test_ctfadapter_mint_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMint(1);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_mint_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_ctfadapter_mint_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMint(5);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_mint_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_ctfadapter_mint_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMint(10);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_mint_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                            MERGE (SELL vs SELL)
    //////////////////////////////////////////////////////////////*/

    function test_ctfadapter_merge_1maker() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMerge(1);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_merge_1maker");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_ctfadapter_merge_5makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMerge(5);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_merge_5makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_ctfadapter_merge_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareMerge(10);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_merge_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                    COMBO: COMPLEMENTARY + MINT
    //////////////////////////////////////////////////////////////*/

    function test_ctfadapter_combo_complementary_mint_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMint(10);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_combo_complementary_mint_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_ctfadapter_combo_complementary_mint_20makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMint(20);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_combo_complementary_mint_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                    COMBO: COMPLEMENTARY + MERGE
    //////////////////////////////////////////////////////////////*/

    function test_ctfadapter_combo_complementary_merge_10makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMerge(10);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_combo_complementary_merge_10makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    function test_ctfadapter_combo_complementary_merge_20makers() public {
        (
            Order memory takerOrder,
            Order[] memory makerOrders,
            uint256 takerFillAmount,
            uint256[] memory fillAmounts,
            uint256[] memory feeAmounts
        ) = _prepareComboComplementaryMerge(20);

        vm.prank(admin);
        vm.startSnapshotGas("ctfadapter_combo_complementary_merge_20makers");
        exchange.matchOrders(conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, 0, feeAmounts);
        vm.stopSnapshotGas();
    }

    /*//////////////////////////////////////////////////////////////
                              HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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
