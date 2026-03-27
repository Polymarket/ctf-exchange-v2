// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

/// @notice Shared helper for computing CREATE2 addresses
library Create2Lib {
    /// @notice Computes the CREATE2 address from deployer, bytecodeHash, and salt
    /// @param deployer - The deployer contract address
    /// @param bytecodeHash - The keccak256 hash of the creation code
    /// @param salt - The CREATE2 salt
    function computeCreate2Address(address deployer, bytes32 bytecodeHash, bytes32 salt)
        internal
        pure
        returns (address result)
    {
        assembly ("memory-safe") {
            // Get free memory pointer
            let ptr := mload(0x40)

            // Construct CREATE2 formula: 0xff ++ deployer (20 bytes) ++ salt (32 bytes) ++ bytecodeHash (32 bytes)
            // Byte 0: 0xff, Bytes 1-20: deployer address
            mstore(ptr, or(0xff00000000000000000000000000000000000000000000000000000000000000, shl(88, deployer)))
            // Bytes 21-52: salt
            mstore(add(ptr, 21), salt)
            // Bytes 53-84: bytecodeHash
            mstore(add(ptr, 53), bytecodeHash)

            // Compute keccak256 of 85 bytes and extract address
            result := and(keccak256(ptr, 85), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }
}
