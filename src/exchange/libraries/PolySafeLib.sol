// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// @title PolySafeLib
/// @notice Helper library to compute Polymarket gnosis safe addresses
library PolySafeLib {
    bytes private constant proxyCreationCode =
        hex"608060405234801561001057600080fd5b5060405161017138038061017183398101604081905261002f916100b9565b6001600160a01b0381166100945760405162461bcd60e51b815260206004820152602260248201527f496e76616c69642073696e676c65746f6e20616464726573732070726f766964604482015261195960f21b606482015260840160405180910390fd5b600080546001600160a01b0319166001600160a01b03929092169190911790556100e7565b6000602082840312156100ca578081fd5b81516001600160a01b03811681146100e0578182fd5b9392505050565b607c806100f56000396000f3fe6080604052600080546001600160a01b0316813563530ca43760e11b1415602857808252602082f35b3682833781823684845af490503d82833e806041573d82fd5b503d81f3fea264697066735822122015938e3bf2c49f5df5c1b7f9569fa85cc5d6f3074bb258a2dc0c7e299bc9e33664736f6c63430008040033";

    /// @notice Gets the Polymarket Gnosis safe address for a signer using a pre-computed bytecode hash
    /// @param signer       - Address of the signer
    /// @param bytecodeHash - Pre-computed keccak256 of the safe proxy creation code
    /// @param deployer     - Address of the deployer contract
    function getSafeAddress(address signer, bytes32 bytecodeHash, address deployer)
        internal
        pure
        returns (address safe)
    {
        return _computeCreate2Address(deployer, bytecodeHash, _getSalt(signer));
    }

    /// @notice Computes the keccak256 hash of the safe proxy creation code with the given master copy
    /// @param masterCopy - Address of the Gnosis Safe master copy
    function computeBytecodeHash(address masterCopy) internal pure returns (bytes32) {
        return keccak256(getContractBytecode(masterCopy));
    }

    function getContractBytecode(address masterCopy) internal pure returns (bytes memory) {
        return abi.encodePacked(proxyCreationCode, abi.encode(masterCopy));
    }

    /// @notice Computes the salt for CREATE2 from a signer address
    /// @dev Equivalent to keccak256(abi.encode(signer)) — hashes the 32-byte right-aligned address
    function _getSalt(address signer) internal pure returns (bytes32 salt) {
        assembly ("memory-safe") {
            // mstore right-aligns the 20-byte address in a 32-byte word (identical to abi.encode(address))
            mstore(0, signer)
            salt := keccak256(0, 32)
        }
    }

    function _computeCreate2Address(address deployer, bytes32 bytecodeHash, bytes32 salt)
        internal
        pure
        returns (address result)
    {
        assembly ("memory-safe") {
            let ptr := mload(64)

            // Construct CREATE2 preimage: 0xff ++ deployer (21 bytes) ++ salt (32 bytes) ++ bytecodeHash (32 bytes)
            mstore(ptr, or(0xff00000000000000000000000000000000000000000000000000000000000000, shl(88, deployer)))
            mstore(add(ptr, 21), salt)
            mstore(add(ptr, 53), bytecodeHash)

            result := and(keccak256(ptr, 85), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }
}
