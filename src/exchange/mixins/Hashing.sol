// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

import { EIP712 } from "@solady/src/utils/EIP712.sol";

import { IHashing } from "../interfaces/IHashing.sol";

import { Order, ORDER_TYPEHASH } from "../libraries/Structs.sol";

abstract contract Hashing is EIP712, IHashing {
    string internal constant DOMAIN_NAME = "Polymarket CTF Exchange";
    string internal constant DOMAIN_VERSION = "2";

    constructor() EIP712() { }

    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        return (DOMAIN_NAME, DOMAIN_VERSION);
    }

    /// @notice Computes the hash for an order
    /// @param order - The order to be hashed
    function hashOrder(Order memory order) public view override returns (bytes32) {
        return _hashTypedData(_createStructHash(order));
    }

    /// @notice Creates the struct hash for an order
    /// @dev This does not include the signature; the signature is downstream of this hash
    function _createStructHash(Order memory order) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            let prev := mload(sub(order, 0x20))
            mstore(sub(order, 0x20), ORDER_TYPEHASH)
            result := keccak256(sub(order, 0x20), 0x180)
            mstore(sub(order, 0x20), prev)
        }
        return result;
    }
}
