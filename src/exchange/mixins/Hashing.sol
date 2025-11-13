// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { EIP712 } from "lib/solady/src/utils/EIP712.sol";

import { IHashing } from "../interfaces/IHashing.sol";

import { Order, UnsignedOrder, ORDER_TYPEHASH } from "../libraries/Structs.sol";

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
        UnsignedOrder memory o = UnsignedOrder({
            salt: order.salt,
            maker: order.maker,
            signer: order.signer,
            taker: order.taker,
            tokenId: order.tokenId,
            makerAmount: order.makerAmount,
            takerAmount: order.takerAmount,
            expiration: order.expiration,
            maxFee: order.maxFee,
            side: order.side,
            signatureType: order.signatureType,
            timestamp: order.timestamp,
            metadata: order.metadata,
            builder: order.builder
        });

        return keccak256(abi.encode(ORDER_TYPEHASH, o));
    }
}
