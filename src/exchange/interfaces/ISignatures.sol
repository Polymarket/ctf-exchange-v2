// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

import { Order } from "../libraries/Structs.sol";

interface ISignaturesEE {
    error InvalidSignature();

    /// @notice Emitted when an order is preapproved
    event OrderPreapproved(bytes32 indexed orderHash);

    /// @notice Emitted when a preapproval is invalidated
    event OrderPreapprovalInvalidated(bytes32 indexed orderHash);
}

abstract contract ISignatures is ISignaturesEE {
    function validateOrderSignature(bytes32 orderHash, Order memory order) public view virtual;
}
