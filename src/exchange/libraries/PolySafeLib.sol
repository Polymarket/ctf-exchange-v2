// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

import { Create2Lib } from "./Create2Lib.sol";

/// @title PolySafeLib
/// @notice Helper library to compute Polymarket gnosis safe addresses
library PolySafeLib {
    /// @notice Gets the Polymarket Gnosis safe address for a signer
    /// @param signer       - Address of the signer
    /// @param bytecodeHash - Pre-computed keccak256 of the safe proxy creation code
    /// @param deployer     - Address of the deployer contract
    function getSafeWalletAddress(address signer, bytes32 bytecodeHash, address deployer)
        internal
        pure
        returns (address safe)
    {
        bytes32 salt = _getSalt(signer);
        safe = Create2Lib.computeCreate2Address(deployer, bytecodeHash, salt);
    }

    /// @notice Computes the keccak256 hash of the proxy creation code with the given master copy
    /// @param implementation - Address of the Gnosis Safe master copy
    function computeBytecodeHash(address implementation) internal pure returns (bytes32) {
        return _computeCreationCodeHash(implementation);
    }

    /// @notice Computes the salt for CREATE2 from a signer address
    /// @param signer - Address of the signer
    /// @return salt - The keccak256 hash of the ABI-encoded signer address
    function _getSalt(address signer) internal pure returns (bytes32 salt) {
        assembly ("memory-safe") {
            mstore(0x00, signer)
            salt := keccak256(0x00, 0x20)
        }
    }

    /// @notice Computes the keccak256 hash of the proxy creation code with the implementation address appended
    /// @dev Writes 369 bytes of proxyCreationCode + 32 bytes abi.encode(implementation) = 401 bytes, then hashes
    function _computeCreationCodeHash(address implementation) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)

            // Write proxyCreationCode (369 bytes) in 32-byte chunks
            mstore(ptr, 0x608060405234801561001057600080fd5b506040516101713803806101718339)
            mstore(add(ptr, 32), 0x8101604081905261002f916100b9565b6001600160a01b038116610094576040)
            mstore(add(ptr, 64), 0x5162461bcd60e51b815260206004820152602260248201527f496e76616c6964)
            mstore(add(ptr, 96), 0x2073696e676c65746f6e20616464726573732070726f76696460448201526119)
            mstore(add(ptr, 128), 0x5960f21b606482015260840160405180910390fd5b600080546001600160a01b)
            mstore(add(ptr, 160), 0x0319166001600160a01b03929092169190911790556100e7565b600060208284)
            mstore(add(ptr, 192), 0x0312156100ca578081fd5b81516001600160a01b03811681146100e0578182fd)
            mstore(add(ptr, 224), 0x5b9392505050565b607c806100f56000396000f3fe6080604052600080546001)
            mstore(add(ptr, 256), 0x600160a01b0316813563530ca43760e11b1415602857808252602082f35b3682)
            mstore(add(ptr, 288), 0x833781823684845af490503d82833e806041573d82fd5b503d81f3fea2646970)
            mstore(add(ptr, 320), 0x66735822122015938e3bf2c49f5df5c1b7f9569fa85cc5d6f3074bb258a2dc0c)
            // Last 17 bytes of proxyCreationCode (right-padded zeros get overwritten by implementation below)
            mstore(add(ptr, 352), 0x7e299bc9e33664736f6c63430008040033000000000000000000000000000000)

            // Write abi.encode(implementation) at offset 369
            mstore(add(ptr, 369), implementation)

            // Hash 401 bytes
            hash := keccak256(ptr, 401)
        }
    }
}
