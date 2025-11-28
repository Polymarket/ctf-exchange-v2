// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { TestHelper } from "./dev/TestHelper.sol";

import { USDC } from "./dev/mocks/USDC.sol";
import { ERC1271Mock } from "./dev/mocks/ERC1271Mock.sol";

import { Deployer } from "./dev/util/Deployer.sol";

import { ERC1155 } from "lib/solady/src/tokens/ERC1155.sol";

import { CTFExchange } from "src/exchange/CTFExchange.sol";
import { IAuthEE } from "src/exchange/interfaces/IAuth.sol";
import { IFeesEE } from "src/exchange/interfaces/IFees.sol";
import { ITradingEE } from "src/exchange/interfaces/ITrading.sol";
import { IPausableEE } from "src/exchange/interfaces/IPausable.sol";
import { IRegistryEE } from "src/exchange/interfaces/IRegistry.sol";
import { ISignaturesEE } from "src/exchange/interfaces/ISignatures.sol";
import { IUserPausableEE } from "src/exchange/interfaces/IUserPausable.sol";

import { IConditionalTokens } from "src/exchange/interfaces/IConditionalTokens.sol";

import { CalculatorHelper } from "src/exchange/libraries/CalculatorHelper.sol";
import {
    ExchangeInitParams,
    Order,
    Side,
    SignatureType,
    UnsignedOrder,
    ORDER_TYPEHASH
} from "src/exchange/libraries/Structs.sol";

contract BaseExchangeTest is
    TestHelper,
    IAuthEE,
    IFeesEE,
    IRegistryEE,
    IPausableEE,
    ITradingEE,
    ISignaturesEE,
    IUserPausableEE
{
    mapping(address => mapping(address => mapping(uint256 => uint256))) private _checkpoints1155;

    USDC public usdc;
    IConditionalTokens public ctf;
    CTFExchange public exchange;

    bytes32 public constant questionID = hex"1234";
    bytes32 public conditionId;
    uint256 public yes;
    uint256 public no;

    address public admin = alice;
    uint256 internal bobPK = 0xB0B;
    uint256 internal carlaPK = 0xCA414;
    address public bob;
    address public carla;
    address public feeReceiver = address(9);

    ERC1271Mock public contractWallet;

    // ERC20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ERC1155 transfer event
    event TransferSingle(
        address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount
    );

    function setUp() public virtual {
        vm.label(admin, "admin");
        bob = vm.addr(bobPK);
        vm.label(bob, "bob");
        carla = vm.addr(carlaPK);
        vm.label(carla, "carla");
        vm.label(feeReceiver, "feeReceiver");

        usdc = new USDC();
        vm.label(address(usdc), "USDC");
        ctf = IConditionalTokens(Deployer.deployConditionalTokens());
        vm.label(address(ctf), "CTF");

        conditionId = _prepareCondition(admin, questionID);
        yes = _getPositionId(2);
        no = _getPositionId(1);

        // Deploy a 1271 contract and set carla as the signer
        contractWallet = new ERC1271Mock(carla);

        vm.startPrank(admin);
        ExchangeInitParams memory p = ExchangeInitParams({
            collateral: address(usdc),
            ctf: address(ctf),
            outcomeTokenFactory: address(ctf),
            proxyFactory: address(0),
            safeFactory: address(0),
            feeReceiver: feeReceiver
        });

        exchange = new CTFExchange(p);
        exchange.registerToken(yes, no, conditionId);
        exchange.addOperator(bob);
        exchange.addOperator(carla);
        vm.stopPrank();
    }

    function _prepareCondition(address oracle, bytes32 _questionId) internal returns (bytes32) {
        ctf.prepareCondition(oracle, _questionId, 2);
        return ctf.getConditionId(oracle, _questionId, 2);
    }

    function _getPositionId(uint256 indexSet) internal view returns (uint256) {
        return ctf.getPositionId(address(usdc), ctf.getCollectionId(bytes32(0), conditionId, indexSet));
    }

    function _createAndSignOrderWithFee(
        uint256 pk,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        uint256 maxFee,
        Side side
    ) internal view returns (Order memory) {
        address maker = vm.addr(pk);
        Order memory order = _createOrder(maker, tokenId, makerAmount, takerAmount, side);
        order.maxFee = maxFee;
        order.signature = _signMessage(pk, exchange.hashOrder(order));
        return order;
    }

    function _createAndSignOrder(uint256 pk, uint256 tokenId, uint256 makerAmount, uint256 takerAmount, Side side)
        internal
        view
        returns (Order memory)
    {
        address maker = vm.addr(pk);
        Order memory order = _createOrder(maker, tokenId, makerAmount, takerAmount, side);
        order.signature = _signMessage(pk, exchange.hashOrder(order));
        return order;
    }

    function _createAndSign1271Order(
        uint256 signerPk,
        address wallet,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side
    ) internal view returns (Order memory) {
        Order memory order = _createOrder(wallet, tokenId, makerAmount, takerAmount, side);
        order.signatureType = SignatureType.POLY_1271;
        order.signature = _signMessage(signerPk, exchange.hashOrder(order));
        return order;
    }

    function _createOrder(address maker, uint256 tokenId, uint256 makerAmount, uint256 takerAmount, Side side)
        internal
        pure
        returns (Order memory)
    {
        Order memory order = Order({
            salt: 1,
            signer: maker,
            maker: maker,
            tokenId: tokenId,
            makerAmount: makerAmount,
            takerAmount: takerAmount,
            expiration: 0,
            maxFee: 0,
            signatureType: SignatureType.EOA,
            side: side,
            timestamp: 0,
            metadata: bytes32(0),
            builder: bytes32(0),
            signature: new bytes(0)
        });
        return order;
    }

    function _signMessage(uint256 pk, bytes32 message) internal pure returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, message);
        sig = abi.encodePacked(r, s, v);
    }

    function _generateOrderHash(address exchangeAddress, Order memory order) internal view returns (bytes32) {
        bytes32 structHash = _getExpectedStructHash(order);
        bytes32 domainSeparator = _getDomainSeparator(exchangeAddress);
        bytes32 orderHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        return orderHash;
    }

    function _getDomainSeparator(address exchangeAddress) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Polymarket CTF Exchange")),
                keccak256(bytes("2")),
                block.chainid,
                exchangeAddress
            )
        );
    }

    function _getExpectedStructHash(Order memory order) internal pure returns (bytes32) {
        UnsignedOrder memory o = UnsignedOrder({
            salt: order.salt,
            maker: order.maker,
            signer: order.signer,
            tokenId: order.tokenId,
            makerAmount: order.makerAmount,
            takerAmount: order.takerAmount,
            expiration: order.expiration,
            maxFee: order.maxFee,
            side: order.side,
            signatureType: order.signatureType,
            timestamp: order.timestamp,
            metadata: order.metadata,
            builder: order.builder
        });

        return keccak256(abi.encode(ORDER_TYPEHASH, o));
    }

    function dealUsdcAndApprove(address to, address spender, uint256 amount) internal {
        vm.startPrank(to);
        dealAndApprove(address(usdc), to, spender, amount);
        vm.stopPrank();
    }

    function dealOutcomeTokensAndApprove(address to, address spender, uint256 tokenId, uint256 amount) internal {
        vm.startPrank(admin);
        approve(address(usdc), address(ctf), type(uint256).max);
        deal(address(usdc), admin, amount);

        uint256[] memory partition = new uint256[](2);
        partition[0] = 1;
        partition[1] = 2;

        IConditionalTokens(ctf).splitPosition(address(usdc), bytes32(0), conditionId, partition, amount);
        ERC1155(address(ctf)).safeTransferFrom(admin, to, tokenId, amount, "");
        vm.stopPrank();

        vm.prank(to);
        ERC1155(address(ctf)).setApprovalForAll(spender, true);
    }

    function assertCollateralBalance(address _who, uint256 _amount) public view {
        assertBalance(address(usdc), _who, _amount);
    }

    function assertCTFBalance(address _who, uint256 _tokenId, uint256 _amount) public view {
        assertBalance1155(address(ctf), _who, _tokenId, _amount);
    }

    function checkpointCollateral(address _who) public {
        checkpointBalance(address(usdc), _who);
    }

    function checkpointCTF(address _who, uint256 _tokenId) public {
        checkpointBalance1155(address(ctf), _who, _tokenId);
    }

    function getCTFBalance(address _who, uint256 _tokenId) public view returns (uint256) {
        return ERC1155(address(ctf)).balanceOf(_who, _tokenId);
    }

    function assertBalance1155(address _token, address _who, uint256 _tokenId, uint256 _amount) public view {
        assertEq(getCTFBalance(_who, _tokenId), _checkpoints1155[_token][_who][_tokenId] + _amount);
    }

    function checkpointBalance1155(address _token, address _who, uint256 _tokenId) public {
        _checkpoints1155[_token][_who][_tokenId] = getCTFBalance(_who, _tokenId);
    }

    function calculatePrice(uint256 makerAmount, uint256 takerAmount, Side side) public pure returns (uint256) {
        return CalculatorHelper._calculatePrice(makerAmount, takerAmount, side);
    }

    function calculateFee(uint256 _feeRate, uint256 _amount, uint256 makerAmount, uint256 takerAmount, Side side)
        internal
        pure
        returns (uint256)
    {
        return CalculatorHelper.calculateFee(_feeRate, _amount, makerAmount, takerAmount, side);
    }

    function _getTakingAmount(uint256 _making, uint256 _makerAmount, uint256 _takerAmount)
        internal
        pure
        returns (uint256)
    {
        return _making * _takerAmount / _makerAmount;
    }
}
