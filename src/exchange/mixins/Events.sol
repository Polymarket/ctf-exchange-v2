// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

import { Side } from "../libraries/Structs.sol";

/// @title Events
abstract contract Events {
    /*//////////////////////////////////////////////////////////////
                        EVENT TOPIC CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev keccak256("OrderFilled(bytes32,address,address,uint8,uint256,uint256,uint256,uint256,bytes32,bytes32)")
    bytes32 private constant _ORDER_FILLED_TOPIC =
        keccak256("OrderFilled(bytes32,address,address,uint8,uint256,uint256,uint256,uint256,bytes32,bytes32)");

    /// @dev keccak256("OrdersMatched(bytes32,address,uint8,uint256,uint256,uint256)")
    bytes32 private constant _ORDERS_MATCHED_TOPIC =
        keccak256("OrdersMatched(bytes32,address,uint8,uint256,uint256,uint256)");

    /// @dev keccak256("FeeCharged(address,uint256)")
    bytes32 private constant _FEE_CHARGED_TOPIC = keccak256("FeeCharged(address,uint256)");

    /*//////////////////////////////////////////////////////////////
                            STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Parameters for the OrderFilled event
    struct OrderFilledParams {
        bytes32 orderHash; // 0x00
        address maker; // 0x20
        address taker; // 0x40
        Side side; // 0x60
        uint256 tokenId; // 0x80
        uint256 makerAmountFilled; // 0xa0
        uint256 takerAmountFilled; // 0xc0
        uint256 fee; // 0xe0
        bytes32 builder; // 0x100
        bytes32 metadata; // 0x120
    }

    /*//////////////////////////////////////////////////////////////
                        EMIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Emits the OrderFilled event
    /// @dev OrderFilled(orderHash, maker, taker, side, tokenId, makerAmountFilled, takerAmountFilled, fee, builder,
    /// metadata)
    function _emitOrderFilledEvent(OrderFilledParams memory p) internal {
        bytes32 t = _ORDER_FILLED_TOPIC;
        assembly ("memory-safe") {
            let m := mload(0x40)
            mstore(m, mload(add(p, 0x60))) // side
            mstore(add(m, 0x20), mload(add(p, 0x80))) // tokenId
            mstore(add(m, 0x40), mload(add(p, 0xa0))) // makerAmountFilled
            mstore(add(m, 0x60), mload(add(p, 0xc0))) // takerAmountFilled
            mstore(add(m, 0x80), mload(add(p, 0xe0))) // fee
            mstore(add(m, 0xa0), mload(add(p, 0x100))) // builder
            mstore(add(m, 0xc0), mload(add(p, 0x120))) // metadata
            log4(m, 0xe0, t, mload(p), mload(add(p, 0x20)), mload(add(p, 0x40)))
        }
    }

    /// @dev Emits OrdersMatched event
    /// @dev OrdersMatched(takerOrderHash, takerOrderMaker, side, tokenId, makerAmountFilled, takerAmountFilled)
    function _emitTakerFilledEvents(OrderFilledParams memory p) internal {
        _emitOrderFilledEvent(p);
        bytes32 t = _ORDERS_MATCHED_TOPIC;
        assembly ("memory-safe") {
            let m := mload(0x40)
            mstore(m, mload(add(p, 0x60))) // side
            mstore(add(m, 0x20), mload(add(p, 0x80))) // tokenId
            mstore(add(m, 0x40), mload(add(p, 0xa0))) // makerAmountFilled
            mstore(add(m, 0x60), mload(add(p, 0xc0))) // takerAmountFilled
            log3(m, 0x80, t, mload(p), mload(add(p, 0x20)))
        }
    }

    /// @dev Emits the FeeCharged event
    /// @dev FeeCharged(receiver, amount)
    function _emitFeeCharged(address receiver, uint256 amount) internal {
        bytes32 t = _FEE_CHARGED_TOPIC;
        assembly ("memory-safe") {
            mstore(0x00, amount)
            log2(0x00, 0x20, t, receiver)
        }
    }
}
