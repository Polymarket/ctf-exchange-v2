// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { OrderStatus, Order, Side } from "../libraries/Structs.sol";

interface ITradingEE {
    error NotTaker();
    error OrderAlreadyFilled();
    error OrderExpired();
    error MakingGtRemaining();
    error NotCrossing();
    error TooLittleTokensReceived();
    error MismatchedTokenIds();
    error FeeExceedsProceeds();

    /// @notice Emitted when an order is filled
    event OrderFilled(
        bytes32 indexed orderHash,
        address indexed maker,
        address indexed taker,
        Side side,
        uint256 tokenId,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled,
        uint256 fee,
        bytes32 builder,
        bytes32 metadata
    );

    /// @notice Emitted when a set of orders is matched
    event OrdersMatched(
        bytes32 indexed takerOrderHash,
        address indexed takerOrderMaker,
        Side side,
        uint256 tokenId,
        uint256 makerAmountFilled,
        uint256 takerAmountFilled
    );
}

interface ITrading is ITradingEE { }
