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

    function _createStructHash(Order memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                order.salt,
                order.maker,
                order.signer,
                order.tokenId,
                order.makerAmount,
                order.takerAmount,
                order.side,
                order.signatureType,
                order.timestamp,
                order.metadata,
                order.builder
            )
        );
    }
}
