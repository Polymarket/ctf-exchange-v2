// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { ITrading } from "../interfaces/ITrading.sol";
import { IUserPausable } from "../interfaces/IUserPausable.sol";

import { CalculatorHelper } from "../libraries/CalculatorHelper.sol";
import { Order, Side, MatchType, OrderStatus } from "../libraries/Structs.sol";

import { Hashing } from "./Hashing.sol";
import { UserPausable } from "./UserPausable.sol";
import { AssetOperations } from "./AssetOperations.sol";
import { Events } from "./Events.sol";
import { Fees } from "./Fees.sol";
import { Signatures } from "./Signatures.sol";

/// @title Trading
/// @notice Implements logic for trading CTF assets
abstract contract Trading is Hashing, AssetOperations, Events, Fees, UserPausable, Signatures, ITrading {
    /// @notice Mapping of orders to their current status
    mapping(bytes32 => OrderStatus) public orderStatus;

    /// @notice Parameters for a prepared maker order (validated and ready for settlement)
    struct PreparedMakerOrder {
        bytes32 orderHash;
        uint256 makingAmount;
        uint256 takingAmount;
        address maker;
        uint256 makerAssetId;
        uint256 takerAssetId;
        Side side;
        MatchType matchType;
        uint256 feeAmount;
        bytes32 builder;
        bytes32 metadata;
        uint256 tokenId;
    }

    /// @notice Gets the status of an order
    /// @param orderHash    - The hash of the order
    function getOrderStatus(bytes32 orderHash) public view returns (OrderStatus memory) {
        return orderStatus[orderHash];
    }

    /// @notice Validates an order
    /// @notice order - The order to be validated
    function validateOrder(Order memory order) external view {
        bytes32 orderHash = hashOrder(order);

        if (orderStatus[orderHash].filled) revert OrderAlreadyFilled();

        _validateOrder(orderHash, order);
    }

    function _validateOrder(bytes32 orderHash, Order memory order) internal view {
        // Validate signature
        validateOrderSignature(orderHash, order);

        // Validate that the user is not paused
        if (isUserPaused(order.maker)) revert UserIsPaused();
    }

    /// @notice Matches orders against each other
    /// @dev Transfers assets between taker and maker orders, settling fees as necessary
    /// @dev Pulls assets from the taker order to the Exchange
    /// @dev Settles maker orders against the Exchange, using the assets received from the taker order
    /// @dev Settles the taker order against the Exchange, using the assets received from the maker orders
    /// @param conditionId          - The conditionId of the market being traded
    /// @param takerOrder           - The active order to be matched
    /// @param makerOrders          - The array of maker orders to be matched against the active order
    /// @param takerFillAmount      - The amount to fill on the taker order, always in terms of the maker amount
    /// @param makerFillAmounts     - The array of amounts to fill on the maker orders, always in terms of
    /// the maker amount
    /// @param takerFeeAmount       - The fee to be charged to the taker order
    /// @param makerFeeAmounts      - The fee to be charged to the maker orders
    function _matchOrders(
        bytes32 conditionId,
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts,
        uint256 takerFeeAmount,
        uint256[] memory makerFeeAmounts
    ) internal {
        (uint256 taking, bytes32 orderHash) = _performOrderChecks(takerOrder, takerFillAmount, takerFeeAmount);

        // Check if all matches are COMPLEMENTARY (all makers have opposite side to taker)
        if (_isAllComplementary(takerOrder.side, makerOrders)) {
            _settleComplementary(
                takerOrder, makerOrders, makerFillAmounts, makerFeeAmounts, orderHash, takerFillAmount, takerFeeAmount
            );
            return;
        }

        (uint256 makerAssetId, uint256 takerAssetId) = _deriveAssetIds(takerOrder);

        // Transfer takerOrder making amount from taker order to the Exchange
        _transfer(takerOrder.maker, address(this), makerAssetId, takerFillAmount);

        // Settle the maker orders (returns accumulated exchange-paid fees)
        uint256 makerExchangeFees =
            _settleMakerOrders(conditionId, takerOrder, makerOrders, makerFillAmounts, makerFeeAmounts);

        // Batch transfer maker SELL fees before taker settlement (so refund logic doesn't see them as leftover)
        if (makerExchangeFees > 0) _transfer(address(this), getFeeReceiver(), 0, makerExchangeFees);

        taking = _updateTakingWithSurplus(taking, takerAssetId);

        // Settle the taker order (returns exchange-paid fee if SELL)
        uint256 takerExchangeFee =
            _settleTakerOrder(takerOrder.side, taking, takerOrder.maker, makerAssetId, takerAssetId, takerFeeAmount);

        _emitTakerFilledEvents(
            OrderFilledParams({
                orderHash: orderHash,
                maker: takerOrder.maker,
                taker: address(this),
                side: takerOrder.side,
                tokenId: takerOrder.tokenId,
                makerAmountFilled: takerFillAmount,
                takerAmountFilled: taking,
                fee: takerFeeAmount,
                builder: takerOrder.builder,
                metadata: takerOrder.metadata
            })
        );

        // Transfer taker SELL fee (if any) after events
        if (takerExchangeFee > 0) _transfer(address(this), getFeeReceiver(), 0, takerExchangeFee);
    }

    /// @notice Settles COMPLEMENTARY orders with direct peer-to-peer transfers
    /// @dev Eliminates exchange as intermediary, saving ~3 transfers per match
    function _settleComplementary(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256[] memory makerFillAmounts,
        uint256[] memory makerFeeAmounts,
        bytes32 takerOrderHash,
        uint256 takerFillAmount,
        uint256 takerFeeAmount
    ) internal {
        address taker = takerOrder.maker;
        bool takerIsBuy = takerOrder.side == Side.BUY;
        uint256 totalMakerFees = 0;
        uint256 totalTakerReceives = 0;

        for (uint256 i = 0; i < makerOrders.length;) {
            (uint256 makerFee, uint256 makerCollateral) = _settleComplementaryMaker(
                takerOrder, makerOrders[i], makerFillAmounts[i], makerFeeAmounts[i], taker, takerIsBuy
            );
            unchecked {
                totalMakerFees += makerFee;
                totalTakerReceives += makerCollateral;
                ++i;
            }
        }

        // Batch transfer accumulated maker SELL fees from taker
        if (totalMakerFees > 0) _transfer(taker, getFeeReceiver(), 0, totalMakerFees);

        // Handle taker settlement
        _settleComplementaryTaker(
            takerOrder, taker, takerIsBuy, totalTakerReceives, takerOrderHash, takerFillAmount, takerFeeAmount
        );
    }

    /// @notice Settles a single maker in COMPLEMENTARY match
    /// @return makerFee - Fee to batch (for maker SELL only)
    /// @return makerCollateral - Collateral received by exchange (for taker SELL only)
    function _settleComplementaryMaker(
        Order memory takerOrder,
        Order memory makerOrder,
        uint256 fillAmount,
        uint256 feeAmount,
        address taker,
        bool takerIsBuy
    ) internal returns (uint256 makerFee, uint256 makerCollateral) {
        _validateOrdersMatch(takerOrder, makerOrder, MatchType.COMPLEMENTARY);

        (uint256 taking, bytes32 orderHash) = _performOrderChecks(makerOrder, fillAmount, feeAmount);

        if (takerIsBuy) {
            // Taker BUY ↔ Maker SELL: direct transfers both ways
            _transfer(makerOrder.maker, taker, makerOrder.tokenId, fillAmount); // CTF: maker → taker
            uint256 makerReceives = taking;
            if (feeAmount > 0) {
                if (feeAmount > taking) revert FeeExceedsProceeds();
                unchecked {
                    makerReceives -= feeAmount;
                }
                makerFee = feeAmount;
                _emitFeeCharged(getFeeReceiver(), feeAmount);
            }
            _transfer(taker, makerOrder.maker, 0, makerReceives); // Collateral: taker → maker
        } else {
            // Taker SELL ↔ Maker BUY: CTF direct, collateral through exchange
            _transfer(taker, makerOrder.maker, takerOrder.tokenId, taking); // CTF: taker → maker
            _transfer(makerOrder.maker, address(this), 0, fillAmount); // Collateral: maker → exchange
            makerCollateral = fillAmount;
            if (feeAmount > 0) _chargeFee(makerOrder.maker, feeAmount);
        }

        _emitOrderFilledEvent(
            OrderFilledParams({
                orderHash: orderHash,
                maker: makerOrder.maker,
                taker: taker,
                side: makerOrder.side,
                tokenId: makerOrder.tokenId,
                makerAmountFilled: fillAmount,
                takerAmountFilled: taking,
                fee: feeAmount,
                builder: makerOrder.builder,
                metadata: makerOrder.metadata
            })
        );
    }

    /// @notice Settles taker in COMPLEMENTARY match
    function _settleComplementaryTaker(
        Order memory takerOrder,
        address taker,
        bool takerIsBuy,
        uint256 totalTakerReceives,
        bytes32 takerOrderHash,
        uint256 takerFillAmount,
        uint256 takerFeeAmount
    ) internal {
        if (takerIsBuy) {
            if (takerFeeAmount > 0) _chargeFee(taker, takerFeeAmount);
        } else {
            uint256 takerProceeds = totalTakerReceives;
            if (takerFeeAmount > 0) {
                if (takerFeeAmount > totalTakerReceives) revert FeeExceedsProceeds();
                unchecked {
                    takerProceeds -= takerFeeAmount;
                }
                _emitFeeCharged(getFeeReceiver(), takerFeeAmount);
                _transfer(address(this), getFeeReceiver(), 0, takerFeeAmount);
            }
            _transfer(address(this), taker, 0, takerProceeds);
        }

        _emitTakerFilledEvents(
            OrderFilledParams({
                orderHash: takerOrderHash,
                maker: taker,
                taker: address(this),
                side: takerOrder.side,
                tokenId: takerOrder.tokenId,
                makerAmountFilled: takerFillAmount,
                takerAmountFilled: takerIsBuy ? takerFillAmount : totalTakerReceives,
                fee: takerFeeAmount,
                builder: takerOrder.builder,
                metadata: takerOrder.metadata
            })
        );
    }

    /// @notice Settles a Taker order
    /// @dev Transfer proceeds from Exchange to order maker
    /// @dev Charge fee on Collateral proceeds if Sell, or on order maker Collateral if Buy
    /// @return exchangeFee - Fee amount to be paid from exchange (for SELL orders), 0 for BUY orders
    function _settleTakerOrder(
        Side side,
        uint256 takingAmount,
        address maker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        uint256 feeAmount
    ) internal returns (uint256 exchangeFee) {
        uint256 proceeds = takingAmount;
        if (side == Side.SELL) {
            // SELL: fee deducted from proceeds, will be batched
            if (feeAmount > takingAmount) revert FeeExceedsProceeds();
            unchecked {
                proceeds = takingAmount - feeAmount; // safety: feeAmount <= takingAmount checked above
            }
            exchangeFee = feeAmount;
        }

        // Transfer order proceeds from the Exchange to the taker order maker
        _transfer(address(this), maker, takerAssetId, proceeds);

        // Charge fees (emit event, transfer batched for SELL or immediate for BUY)
        if (side == Side.SELL) {
            // SELL: emit event now, transfer will be batched later
            if (feeAmount > 0) _emitFeeCharged(getFeeReceiver(), feeAmount);
        } else if (feeAmount > 0) {
            // BUY: fee transferred from maker directly (cannot batch)
            _chargeFee(maker, feeAmount);
        }

        // Refund any leftover tokens
        uint256 refund = _getBalance(makerAssetId);
        if (refund > 0) _transfer(address(this), maker, makerAssetId, refund);
    }

    function _settleMakerOrders(
        bytes32 conditionId,
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256[] memory makerFillAmounts,
        uint256[] memory makerFeeAmounts
    ) internal returns (uint256 totalExchangeFees) {
        uint256 length = makerOrders.length;

        // Phase 1: Prepare all maker orders (validate, transfer from makers, accumulate batch totals)
        PreparedMakerOrder[] memory prepared = new PreparedMakerOrder[](length);
        uint256 totalMintAmount = 0;
        uint256 totalMergeAmount = 0;

        for (uint256 i = 0; i < length;) {
            prepared[i] = _prepareMakerOrder(takerOrder, makerOrders[i], makerFillAmounts[i], makerFeeAmounts[i]);

            // Accumulate batch totals based on match type
            if (prepared[i].matchType == MatchType.MINT) {
                unchecked {
                    totalMintAmount += prepared[i].takingAmount; // safety: token amounts can't realistically overflow
                    // uint256
                }
            } else if (prepared[i].matchType == MatchType.MERGE) {
                unchecked {
                    totalMergeAmount += prepared[i].makingAmount; // safety: token amounts can't realistically overflow
                    // uint256
                }
            }
            unchecked {
                ++i; // safety: i < length which fits in memory
            }
        }

        // Phase 2: Execute batched CTF operations (one mint and/or one merge)
        if (totalMintAmount > 0) _mint(conditionId, totalMintAmount);
        if (totalMergeAmount > 0) _merge(conditionId, totalMergeAmount);

        // Phase 3: Distribute proceeds to all makers, accumulating exchange-paid fees
        for (uint256 i = 0; i < length;) {
            unchecked {
                totalExchangeFees += _distributeMakerProceeds(prepared[i], takerOrder.maker); // safety: each fee <=
                // takingAmount (FeeExceedsProceeds), sum bounded by real token supply
            }
            unchecked {
                ++i; // safety: i < length which fits in memory
            }
        }
    }

    /// @notice Prepares a maker order for batch settlement
    /// @dev Validates, calculates amounts, transfers from maker to exchange
    /// @param takerOrder   - The taker order
    /// @param makerOrder   - The maker order
    /// @param fillAmount   - The fill amount
    /// @param feeAmount    - The fee amount
    /// @return prepared    - The prepared maker order data
    function _prepareMakerOrder(Order memory takerOrder, Order memory makerOrder, uint256 fillAmount, uint256 feeAmount)
        internal
        returns (PreparedMakerOrder memory prepared)
    {
        MatchType matchType = _deriveMatchType(takerOrder, makerOrder);

        // Ensure taker order and maker order match
        _validateOrdersMatch(takerOrder, makerOrder, matchType);

        (uint256 taking, bytes32 orderHash) = _performOrderChecks(makerOrder, fillAmount, feeAmount);

        (uint256 makerAssetId, uint256 takerAssetId) = _deriveAssetIds(makerOrder);

        // Transfer making amount from maker to the Exchange
        _transfer(makerOrder.maker, address(this), makerAssetId, fillAmount);

        prepared = PreparedMakerOrder({
            orderHash: orderHash,
            makingAmount: fillAmount,
            takingAmount: taking,
            maker: makerOrder.maker,
            makerAssetId: makerAssetId,
            takerAssetId: takerAssetId,
            side: makerOrder.side,
            matchType: matchType,
            feeAmount: feeAmount,
            builder: makerOrder.builder,
            metadata: makerOrder.metadata,
            tokenId: makerOrder.tokenId
        });
    }

    /// @notice Distributes proceeds to a maker after batch CTF operations
    /// @param p            - The prepared maker order data
    /// @param takerMaker   - The taker order's maker address (for event)
    /// @return exchangeFee - Fee amount to be paid from exchange (for SELL orders), 0 for BUY orders
    function _distributeMakerProceeds(PreparedMakerOrder memory p, address takerMaker)
        internal
        returns (uint256 exchangeFee)
    {
        // For COMPLEMENTARY matches, no CTF operation was done, tokens already available
        // For MINT/MERGE, batch operation already executed

        uint256 proceeds = p.takingAmount;
        if (p.side == Side.SELL) {
            // SELL: fee deducted from proceeds, will be batched
            if (p.feeAmount > p.takingAmount) revert FeeExceedsProceeds();
            unchecked {
                proceeds = p.takingAmount - p.feeAmount; // safety: feeAmount <= takingAmount checked above
            }
            exchangeFee = p.feeAmount;
        }

        // Transfer order proceeds from the Exchange to the order maker
        _transfer(address(this), p.maker, p.takerAssetId, proceeds);

        // Charge fees (emit event, transfer batched for SELL or immediate for BUY)
        if (p.side == Side.SELL) {
            // SELL: emit event now, transfer will be batched later
            if (p.feeAmount > 0) _emitFeeCharged(getFeeReceiver(), p.feeAmount);
        } else if (p.feeAmount > 0) {
            // BUY: fee transferred from maker directly (cannot batch)
            _chargeFee(p.maker, p.feeAmount);
        }

        // Emit the order filled event
        _emitOrderFilledEvent(
            OrderFilledParams({
                orderHash: p.orderHash,
                maker: p.maker,
                taker: takerMaker,
                side: p.side,
                tokenId: p.tokenId,
                makerAmountFilled: p.makingAmount,
                takerAmountFilled: p.takingAmount,
                fee: p.feeAmount,
                builder: p.builder,
                metadata: p.metadata
            })
        );
    }

    /// @notice Performs common order computations and validation
    /// 1) Computes the order hash
    /// 2) Validates the order
    /// 3) Updates the order status in storage
    /// 4) Computes taking amount
    /// 5) Validates fee against max fee rate (lazy-loads maxFeeRateBps only when fee != 0)
    /// @param order        - The order being prepared
    /// @param making       - The amount of the order being filled, in terms of maker amount
    /// @param fee          - The fee charged to the order by the operator
    function _performOrderChecks(Order memory order, uint256 making, uint256 fee)
        internal
        returns (uint256 takingAmount, bytes32 orderHash)
    {
        orderHash = hashOrder(order);

        // Validate order
        _validateOrder(orderHash, order);

        // Update the order status in storage
        _updateOrderStatus(orderHash, order, making);

        // Calculate taking amount
        takingAmount = CalculatorHelper.calculateTakingAmount(making, order.makerAmount, order.takerAmount);

        // Validate fee against max fee rate (reads storage only when fee is non-zero)
        if (fee != 0) {
            uint256 cashValue = order.side == Side.BUY ? making : takingAmount;
            validateFeeWithMaxFeeRate(fee, cashValue, maxFeeRateBps);
        }
    }

    function _deriveMatchType(Order memory takerOrder, Order memory makerOrder) internal pure returns (MatchType) {
        // Enum values: Side.Buy: 0 Side.Sell 1
        // Enum math: add one to the takerSide, and multiply it by 1 IF it's equal to the makerSide, OR
        // multiply by zero if it isn't

        MatchType matchType;
        Side takerOrderSide = takerOrder.side;
        Side makerOrderSide = makerOrder.side;
        assembly ("memory-safe") {
            matchType := mul(add(takerOrderSide, 1), eq(takerOrderSide, makerOrderSide))
        }
        return matchType;
    }

    function _isAllComplementary(Side takerSide, Order[] memory makerOrders) internal pure returns (bool result) {
        assembly {
            result := 1
            let length := mload(makerOrders)
            let ptr := add(makerOrders, 0x20)
            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                let orderPtr := mload(add(ptr, shl(5, i)))
                // side is at offset 0xC0 in Order struct
                let side := mload(add(orderPtr, 0xC0))
                if eq(side, takerSide) {
                    result := 0
                    break
                }
            }
        }
    }

    function _deriveAssetIds(Order memory order) internal pure returns (uint256 makerAssetId, uint256 takerAssetId) {
        // SIDE * tokenId, tokenId - SIDE * tokenId
        // buy: 0, tokenId
        // sell: tokenId, 0
        Side side = order.side;
        uint256 tokenId = order.tokenId;
        assembly ("memory-safe") {
            makerAssetId := mul(side, tokenId)
            takerAssetId := sub(tokenId, makerAssetId)
        }
    }

    /// @notice Ensures the taker and maker orders can be matched against each other
    /// @param takerOrder   - The taker order
    /// @param makerOrder   - The maker order
    function _validateOrdersMatch(Order memory takerOrder, Order memory makerOrder, MatchType matchType) internal pure {
        if (matchType == MatchType.COMPLEMENTARY) {
            // For BUY vs SELL on the same token, the crossing condition is:
            //   buyPrice >= sellPrice
            //
            // Expressed in order terms:
            //   (makerAmount_buy / takerAmount_buy) >= (takerAmount_sell / makerAmount_sell)
            //
            // Cross-multiplying representation:
            //   makerAmount_A * makerAmount_B >= takerAmount_A * takerAmount_B
            //
            // handles the takerAmount == 0 edge case (RHS is 0, always true).
            if (takerOrder.makerAmount * makerOrder.makerAmount < takerOrder.takerAmount * makerOrder.takerAmount) {
                revert NotCrossing();
            }

            if (takerOrder.tokenId != makerOrder.tokenId) revert MismatchedTokenIds();
        } else {
            if (!CalculatorHelper.isCrossing(takerOrder, makerOrder)) revert NotCrossing();
        }
    }

    function _chargeFee(address payer, uint256 fee) internal {
        // Charge fee to the payer if any
        if (fee > 0) {
            address receiver = getFeeReceiver();
            _transfer(payer, receiver, 0, fee);
            _emitFeeCharged(receiver, fee);
        }
    }

    function _updateOrderStatus(bytes32 orderHash, Order memory order, uint256 makingAmount)
        internal
        returns (uint256 remaining)
    {
        OrderStatus storage status = orderStatus[orderHash];

        // Single SLOAD: read packed slot and extract both filled and remaining
        bool filled;
        assembly {
            let packed := sload(status.slot)
            filled := and(packed, 0xff)
            remaining := shr(8, packed)
        }

        // Validate that the order can be filled
        if (filled) revert OrderAlreadyFilled();

        // Update remaining if the order is new/has not been filled
        remaining = remaining == 0 ? order.makerAmount : remaining;

        // Throw if the makingAmount(amount to be filled) is greater than the amount available
        if (makingAmount > remaining) revert MakingGtRemaining();

        unchecked {
            remaining = remaining - makingAmount; // safety: makingAmount <= remaining checked above
        }

        // Single SSTORE: pack filled (1 byte) and remaining (31 bytes) into one slot
        assembly {
            let packed := or(shl(8, remaining), iszero(remaining))
            sstore(status.slot, packed)
        }
    }

    function _updateTakingWithSurplus(uint256 minimumAmount, uint256 tokenId) internal view returns (uint256) {
        uint256 actualAmount = _getBalance(tokenId);
        if (actualAmount < minimumAmount) revert TooLittleTokensReceived();
        return actualAmount;
    }
}
