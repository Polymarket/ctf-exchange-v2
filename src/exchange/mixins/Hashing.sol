// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { EIP712 } from "lib/solady/src/utils/EIP712.sol";

import { IHashing } from "../interfaces/IHashing.sol";

import { Order, ORDER_TYPEHASH } from "../libraries/Structs.sol";

abstract contract Hashing is EIP712, IHashing {
    string internal constant domainName = "Polymarket CTF Exchange";
    string internal constant domainVersion = "2";

    constructor() EIP712() { }

    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        return (domainName, domainVersion);
    }

    /// @notice Computes the hash for an order
    /// @param order - The order to be hashed
    function hashOrder(Order memory order) public view override returns (bytes32) {
        return _hashTypedData(_createStructHash(order));
    }

    function _createStructHash(Order memory order) internal pure returns (bytes32 result) {
        bytes32 typehash = ORDER_TYPEHASH;
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            mstore(m, typehash)
            mstore(add(m, 0x20), mload(order)) // salt
            mstore(add(m, 0x40), mload(add(order, 0x20))) // maker
            mstore(add(m, 0x60), mload(add(order, 0x40))) // signer
            mstore(add(m, 0x80), mload(add(order, 0x60))) // tokenId
            mstore(add(m, 0xa0), mload(add(order, 0x80))) // makerAmount
            mstore(add(m, 0xc0), mload(add(order, 0xa0))) // takerAmount
            mstore(add(m, 0xe0), mload(add(order, 0xc0))) // side
            mstore(add(m, 0x100), mload(add(order, 0xe0))) // signatureType
            mstore(add(m, 0x120), mload(add(order, 0x100))) // timestamp
            mstore(add(m, 0x140), mload(add(order, 0x120))) // metadata
            mstore(add(m, 0x160), mload(add(order, 0x140))) // builder
            result := keccak256(m, 0x180)
        }
    }
}
