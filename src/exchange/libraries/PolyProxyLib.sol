// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// @notice Helper library to compute polymarket proxy wallet addresses
library PolyProxyLib {
    /// @notice Gets the polymarket proxy address for a signer
    /// @param signer - Address of the signer
    function getProxyWalletAddress(address signer, address implementation, address deployer)
        internal
        pure
        returns (address proxyWallet)
    {
        return _computeCreate2Address(deployer, implementation, _getSalt(signer));
    }

    /// @notice Computes the salt for CREATE2 from a signer address
    /// @param signer - Address of the signer
    /// @return salt - The keccak256 hash of the packed signer address
    function _getSalt(address signer) internal pure returns (bytes32 salt) {
        assembly ("memory-safe") {
            // Store address at 0x20 (right-aligned: first 12 bytes are zero, last 20 bytes are the address)
            mstore(0x20, signer)
            // Hash 20 bytes starting at position 44 (32 + 12)
            salt := keccak256(44, 20)
        }
    }

    function _computeCreate2Address(address from, address target, bytes32 salt) internal pure returns (address result) {
        bytes32 bytecodeHash = _computeCreationCodeHash(from, target);

        assembly ("memory-safe") {
            // Get free memory pointer
            let ptr := mload(0x40)

            // Construct CREATE2 formula: 0xff ++ from (20 bytes) ++ salt (32 bytes) ++ bytecodeHash (32 bytes)
            // Byte 0: 0xff, Bytes 1-20: from address
            mstore(ptr, or(0xff00000000000000000000000000000000000000000000000000000000000000, shl(88, from)))
            // Bytes 21-52: salt
            mstore(add(ptr, 21), salt)
            // Bytes 53-84: bytecodeHash
            mstore(add(ptr, 53), bytecodeHash)

            // Compute keccak256 of 85 bytes and extract address
            result := and(keccak256(ptr, 85), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function _computeCreationCodeHash(address deployer, address target) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            // Allocate from free memory pointer: only 167 bytes (no length field needed)
            let ptr := mload(0x40)

            // Write buffer section (99 bytes)
            // Bytes 0-31: first byte 0x3d, then 31 zero bytes
            mstore(ptr, 0x3d00000000000000000000000000000000000000000000000000000000000000)
            // Bytes 1-32: OR 12-byte prefix (with trailing zeros) with 20-byte deployer
            mstore(add(ptr, 1), or(0x3d606380380380913d393d730000000000000000000000000000000000000000, deployer))
            // Bytes 33-64: 19 non-zero bytes of bytecode, then 13 zero bytes
            mstore(add(ptr, 33), 0x5af4602a57600080fd5b602d8060366000396000000000000000000000000000)
            // Bytes 65-96: OR 12-byte prefix (with leading zeros) with 20-byte target
            mstore(add(ptr, 52), or(0x00f3363d3d373d3d3d363d730000000000000000000000000000000000000000, target))
            // Bytes 96-127: remaining bytes of buffer + start of consData
            mstore(add(ptr, 84), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            // Write consData section (68 bytes)
            mstore(add(ptr, 99), 0x52e831dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 103), 0x0000000000000000000000000000000000000000000000000000000000000020)
            mstore(add(ptr, 135), 0x0000000000000000000000000000000000000000000000000000000000000000)

            // Hash the creation code: 167 bytes total
            hash := keccak256(ptr, 167)
        }
    }
}
