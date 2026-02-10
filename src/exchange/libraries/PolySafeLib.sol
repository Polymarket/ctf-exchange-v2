// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// @title PolySafeLib
/// @notice Helper library to compute Polymarket gnosis safe addresses
library PolySafeLib {
    bytes private constant proxyCreationCode =
        hex"608060405234801561001057600080fd5b5060405161017138038061017183398101604081905261002f916100b9565b6001600160a01b0381166100945760405162461bcd60e51b815260206004820152602260248201527f496e76616c69642073696e676c65746f6e20616464726573732070726f766964604482015261195960f21b606482015260840160405180910390fd5b600080546001600160a01b0319166001600160a01b03929092169190911790556100e7565b6000602082840312156100ca578081fd5b81516001600160a01b03811681146100e0578182fd5b9392505050565b607c806100f56000396000f3fe6080604052600080546001600160a01b0316813563530ca43760e11b1415602857808252602082f35b3682833781823684845af490503d82833e806041573d82fd5b503d81f3fea264697066735822122015938e3bf2c49f5df5c1b7f9569fa85cc5d6f3074bb258a2dc0c7e299bc9e33664736f6c63430008040033";

    /// @notice Gets the Polymarket Gnosis safe address for a signer
    /// @param signer   - Address of the signer
    /// @param deployer - Address of the deployer contract
    function getSafeAddress(address signer, address implementation, address deployer)
        internal
        pure
        returns (address safe)
    {
        bytes32 bytecodeHash = _computeCreationCodeHash(implementation);
        bytes32 salt = _getSalt(signer);
        safe = _computeCreate2Address(deployer, bytecodeHash, salt);
    }

    function getContractBytecode(address masterCopy) internal pure returns (bytes memory) {
        return abi.encodePacked(proxyCreationCode, abi.encode(masterCopy));
    }

    /// @notice Computes the salt for CREATE2 from a signer address
    /// @param signer - Address of the signer
    /// @return salt - The keccak256 hash of the abi.encoded signer address
    function _getSalt(address signer) internal pure returns (bytes32 salt) {
        assembly ("memory-safe") {
            mstore(0x00, signer)
            salt := keccak256(0x00, 0x20)
        }
    }

    /// @notice Computes the CREATE2 address from deployer, bytecodeHash, and salt
    function _computeCreate2Address(address deployer, bytes32 bytecodeHash, bytes32 salt)
        internal
        pure
        returns (address result)
    {
        assembly ("memory-safe") {
            let ptr := mload(0x40)

            // 0xff ++ deployer (20 bytes) ++ salt (32 bytes) ++ bytecodeHash (32 bytes)
            mstore(ptr, or(0xff00000000000000000000000000000000000000000000000000000000000000, shl(88, deployer)))
            mstore(add(ptr, 21), salt)
            mstore(add(ptr, 53), bytecodeHash)

            result := and(keccak256(ptr, 85), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    /// @notice Computes the keccak256 hash of the proxy creation code with the implementation address appended
    /// @dev Writes 369 bytes of proxyCreationCode + 32 bytes abi.encode(implementation) = 401 bytes, then hashes
    function _computeCreationCodeHash(address implementation) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            let ptr := mload(0x40)

            // Write proxyCreationCode (369 bytes) in 32-byte chunks
            mstore(ptr, 0x608060405234801561001057600080fd5b506040516101713803806101718339)
            mstore(add(ptr, 0x20), 0x8101604081905261002f916100b9565b6001600160a01b038116610094576040)
            mstore(add(ptr, 0x40), 0x5162461bcd60e51b815260206004820152602260248201527f496e76616c6964)
            mstore(add(ptr, 0x60), 0x2073696e676c65746f6e20616464726573732070726f76696460448201526119)
            mstore(add(ptr, 0x80), 0x5960f21b606482015260840160405180910390fd5b600080546001600160a01b)
            mstore(add(ptr, 0xa0), 0x0319166001600160a01b03929092169190911790556100e7565b600060208284)
            mstore(add(ptr, 0xc0), 0x0312156100ca578081fd5b81516001600160a01b03811681146100e0578182fd)
            mstore(add(ptr, 0xe0), 0x5b9392505050565b607c806100f56000396000f3fe6080604052600080546001)
            mstore(add(ptr, 0x100), 0x600160a01b0316813563530ca43760e11b1415602857808252602082f35b3682)
            mstore(add(ptr, 0x120), 0x833781823684845af490503d82833e806041573d82fd5b503d81f3fea2646970)
            mstore(add(ptr, 0x140), 0x66735822122015938e3bf2c49f5df5c1b7f9569fa85cc5d6f3074bb258a2dc0c)
            // Last 17 bytes of proxyCreationCode (right-padded zeros get overwritten by implementation below)
            mstore(add(ptr, 0x160), 0x7e299bc9e33664736f6c63430008040033000000000000000000000000000000)

            // Write abi.encode(implementation) at offset 369 (0x171)
            mstore(add(ptr, 0x171), implementation)

            // Hash 401 bytes (0x191)
            hash := keccak256(ptr, 0x191)
        }
    }
}
