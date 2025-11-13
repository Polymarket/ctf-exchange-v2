// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { Order, Side, SignatureType } from "src/exchange/libraries/Structs.sol";

contract ERC1271SignatureTest is BaseExchangeTest {
    function test_validate1271Signature() public view {
        Order memory order =
            _createAndSign1271Order(carlaPK, address(contractWallet), yes, 50_000_000, 100_000_000, Side.BUY);
        exchange.validateOrderSignature(exchange.hashOrder(order), order);
    }

    function test_validate1271Signature_revert_incorrectSigner() public {
        Order memory order = _createOrder(address(contractWallet), yes, 50_000_000, 100_000_000, Side.BUY);
        order.signatureType = SignatureType.POLY_1271;
        bytes32 orderHash = exchange.hashOrder(order);
        order.signature = _signMessage(bobPK, orderHash);
        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrderSignature(orderHash, order);
    }

    function test_validate1271Signature_revert_sigType() public {
        Order memory order = _createOrder(address(contractWallet), yes, 50_000_000, 100_000_000, Side.BUY);
        order.signatureType = SignatureType.EOA;
        bytes32 orderHash = exchange.hashOrder(order);
        order.signature = _signMessage(carlaPK, orderHash);
        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrderSignature(orderHash, order);
    }

    function test_validate1271Signature_revert_nonContract() public {
        Order memory order = _createOrder(carla, yes, 50_000_000, 100_000_000, Side.BUY);
        order.signatureType = SignatureType.POLY_1271;
        bytes32 orderHash = exchange.hashOrder(order);
        order.signature = _signMessage(carlaPK, orderHash);
        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrderSignature(orderHash, order);
    }

    function test_validate1271Signature_revert_invalidContract() public {
        // revert when using a non 1271 contract
        Order memory order = _createOrder(address(usdc), yes, 50_000_000, 100_000_000, Side.BUY);
        order.signatureType = SignatureType.POLY_1271;
        bytes32 orderHash = exchange.hashOrder(order);
        order.signature = _signMessage(carlaPK, orderHash);
        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrderSignature(orderHash, order);
    }

    function test_validate1271Signature_revert_invalidSignerMaker() public {
        Order memory order = _createOrder(address(contractWallet), yes, 50_000_000, 100_000_000, Side.BUY);
        order.signatureType = SignatureType.POLY_1271;
        // signer == carla, maker == contractWallet
        order.signer = carla;
        bytes32 orderHash = exchange.hashOrder(order);
        order.signature = _signMessage(carlaPK, orderHash);
        vm.expectRevert(InvalidSignature.selector);
        exchange.validateOrderSignature(orderHash, order);
    }
}
