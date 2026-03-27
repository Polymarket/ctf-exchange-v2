// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import { ECDSA } from "@solady/src/utils/ECDSA.sol";
import { SignatureCheckerLib } from "@solady/src/utils/SignatureCheckerLib.sol";

import { SignatureType, Order } from "../libraries/Structs.sol";

import { ISignatures } from "../interfaces/ISignatures.sol";

import { PolyFactoryHelper } from "./PolyFactoryHelper.sol";

/// @title Signatures
/// @notice Maintains logic that defines the various signature types and validates them
abstract contract Signatures is ISignatures, PolyFactoryHelper {
    constructor(address _proxyFactory, address _safeFactory) PolyFactoryHelper(_proxyFactory, _safeFactory) { }

    mapping(bytes32 => bool) internal preapproved;

    /// @notice Sets an order as preapproved
    /// @param orderHash - The hash of the order
    /// @param order     - The order
    function _preapproveOrder(bytes32 orderHash, Order memory order) internal {
        require(
            _isValidSignature(order.signer, order.maker, orderHash, order.signature, order.signatureType),
            InvalidSignature()
        );

        preapproved[orderHash] = true;

        emit OrderPreapproved(orderHash);
    }

    /// @notice Invalidates a preapproval
    /// @param orderHash - The hash of the order
    function _invalidatePreapprovedOrder(bytes32 orderHash) internal {
        preapproved[orderHash] = false;

        emit OrderPreapprovalInvalidated(orderHash);
    }

    /// @notice Validates the signature of an order
    /// @dev If the signature is empty, only preapproval is checked. This allows operators to omit
    /// the signature for preapproved orders, saving calldata gas and skipping ECDSA recovery.
    /// @param orderHash - The hash of the order
    /// @param order     - The order
    function validateOrderSignature(bytes32 orderHash, Order memory order) public view override {
        if (order.signature.length == 0) {
            require(_isPreapproved(orderHash), InvalidSignature());
        } else {
            require(
                _isValidSignature(order.signer, order.maker, orderHash, order.signature, order.signatureType),
                InvalidSignature()
            );
        }
    }

    /// @notice Verifies a signature for signed Order structs
    /// @param signer           - Address of the signer
    /// @param associated       - Address associated with the signer.
    ///                           For signature type EOA, this MUST be the same as the signer address.
    ///                           For signature types POLY_PROXY and POLY_GNOSIS_SAFE, this is the address of the proxy
    ///                           or the safe
    ///                           For signature type POLY_1271, this is the address of the contract
    /// @param structHash       - The hash of the struct being verified
    /// @param signature        - The signature to be verified
    /// @param signatureType    - The signature type to be verified
    function _isValidSignature(
        address signer,
        address associated,
        bytes32 structHash,
        bytes memory signature,
        SignatureType signatureType
    ) internal view returns (bool) {
        if (signatureType == SignatureType.EOA) {
            // EOA
            return _verifyEOASignature(signer, associated, structHash, signature);
        } else if (signatureType == SignatureType.POLY_GNOSIS_SAFE) {
            // POLY_GNOSIS_SAFE
            return _verifyPolySafeSignature(signer, associated, structHash, signature);
        } else if (signatureType == SignatureType.POLY_1271) {
            // POLY_1271
            return _verifyPoly1271Signature(signer, associated, structHash, signature);
        } else {
            // POLY_PROXY
            return _verifyPolyProxySignature(signer, associated, structHash, signature);
        }
    }

    /// @notice Verifies an EOA ECDSA signature
    /// Verifies that:
    /// 1) the signature is valid
    /// 2) the signer and maker are the same
    /// @param signer      - The address of the signer
    /// @param maker       - The address of the maker
    /// @param structHash  - The hash of the struct being verified
    /// @param signature   - The signature to be verified
    function _verifyEOASignature(address signer, address maker, bytes32 structHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return (signer == maker) && _verifyECDSASignature(signer, structHash, signature);
    }

    /// @notice Verifies an ECDSA signature
    /// @dev Reverts if the signature length is invalid or the recovered signer is the zero address
    /// @param signer      - Address of the signer
    /// @param structHash  - The hash of the struct being verified
    /// @param signature   - The signature to be verified
    function _verifyECDSASignature(address signer, bytes32 structHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return ECDSA.recover(structHash, signature) == signer;
    }

    /// @notice Verifies a signature signed by a Polymarket proxy wallet
    // Verifies that:
    // 1) the ECDSA signature is valid
    // 2) the Proxy wallet is owned by the signer
    /// @param signer       - Address of the signer
    /// @param proxyWallet  - Address of the poly proxy wallet
    /// @param structHash   - Hash of the struct being verified
    /// @param signature    - Signature to be verified
    function _verifyPolyProxySignature(address signer, address proxyWallet, bytes32 structHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return _verifyECDSASignature(signer, structHash, signature) && getProxyWalletAddress(signer) == proxyWallet;
    }

    /// @notice Verifies a signature signed by a Polymarket Gnosis safe
    // Verifies that:
    // 1) the ECDSA signature is valid
    // 2) the Safe is owned by the signer
    /// @param signer      - Address of the signer
    /// @param safeAddress - Address of the safe
    /// @param hash        - Hash of the struct being verified
    /// @param signature   - Signature to be verified
    function _verifyPolySafeSignature(address signer, address safeAddress, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return _verifyECDSASignature(signer, hash, signature) && getSafeWalletAddress(signer) == safeAddress;
    }

    /// @notice Verifies a signature signed by a smart contract
    /// @param signer           - Address of the 1271 smart contract
    /// @param maker            - Address of the 1271 smart contract
    /// @param hash             - Hash of the struct being verified
    /// @param signature        - Signature to be verified
    function _verifyPoly1271Signature(address signer, address maker, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return (signer == maker) && maker.code.length > 0
            && SignatureCheckerLib.isValidSignatureNow(maker, hash, signature);
    }

    function _isPreapproved(bytes32 orderHash) internal view returns (bool) {
        return preapproved[orderHash];
    }
}
