// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IFees } from "../interfaces/IFees.sol";
import { IHashing } from "../interfaces/IHashing.sol";
import { ITrading } from "../interfaces/ITrading.sol";
import { IRegistry } from "../interfaces/IRegistry.sol";
import { ISignatures } from "../interfaces/ISignatures.sol";
import { IUserPausable } from "../interfaces/IUserPausable.sol";
import { IAssetOperations } from "../interfaces/IAssetOperations.sol";

import { CalculatorHelper } from "../libraries/CalculatorHelper.sol";
import { Order, Side, MatchType, OrderStatus } from "../libraries/Structs.sol";

/// @title Trading
/// @notice Implements logic for trading CTF assets
abstract contract Trading is IFees, ITrading, IHashing, IRegistry, ISignatures, IAssetOperations, IUserPausable {
    /// @notice Mapping of orders to their current status
    mapping(bytes32 => OrderStatus) public orderStatus;

    /// @notice Parameters for the OrderFilled event
    struct OrderFilledParams {
        bytes32 orderHash;
        address maker;
        address taker;
        Side side;
        uint256 tokenId;
        uint256 makerAmountFilled;
        uint256 takerAmountFilled;
        uint256 fee;
        bytes32 builder;
        bytes32 metadata;
    }

    /// @notice Gets the status of an order
    /// @param orderHash    - The hash of the order
    function getOrderStatus(bytes32 orderHash) public view returns (OrderStatus memory) {
        return orderStatus[orderHash];
    }

    /// @notice Validates an order
    /// @notice order - The order to be validated
    function validateOrder(Order memory order) public view {
        bytes32 orderHash = hashOrder(order);
        _validateOrder(orderHash, order);
    }

    function _validateOrder(bytes32 orderHash, Order memory order) internal view {
        // Validate order expiration
        if (order.expiration > 0 && order.expiration < block.timestamp) revert OrderExpired();

        // Validate signature
        validateOrderSignature(orderHash, order);

        // Validate that the user is not paused
        if (isUserPaused(order.maker)) revert UserIsPaused();

        // Validate the token to be traded
        validateTokenId(order.tokenId);

        // Validate that the order can be filled
        if (orderStatus[orderHash].filled) revert OrderAlreadyFilled();
    }

    /// @notice Matches orders against each other
    /// @dev Transfers assets between taker and maker orders, settling fees as necessary
    /// @dev Pulls assets from the taker order to the Exchange
    /// @dev Settles maker orders against the Exchange, using the assets received from the taker order
    /// @dev Settles the taker order against the Exchange, using the assets received from the maker orders
    /// @param takerOrder           - The active order to be matched
    /// @param makerOrders          - The array of maker orders to be matched against the active order
    /// @param takerFillAmount      - The amount to fill on the taker order, always in terms of the maker amount
    /// @param makerFillAmounts     - The array of amounts to fill on the maker orders, always in terms of
    /// the maker amount
    /// @param takerFeeAmount       - The fee to be charged to the taker order
    /// @param makerFeeAmounts      - The fee to be charged to the maker orders
    function _matchOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts,
        uint256 takerFeeAmount,
        uint256[] memory makerFeeAmounts
    ) internal {
        uint256 making = takerFillAmount;

        uint256 maxFeeRate = getMaxFeeRate();

        (uint256 taking, bytes32 orderHash) = _performOrderChecks(takerOrder, making, takerFeeAmount, maxFeeRate);
        (uint256 makerAssetId, uint256 takerAssetId) = _deriveAssetIds(takerOrder);

        // Transfer takerOrder making amount from taker order to the Exchange
        _transfer(takerOrder.maker, address(this), makerAssetId, making);

        // Settle the maker orders
        _settleMakerOrders(takerOrder, makerOrders, makerFillAmounts, makerFeeAmounts, maxFeeRate);

        taking = _updateTakingWithSurplus(taking, takerAssetId);

        // Settle the taker order
        _settleTakerOrder(takerOrder.side, taking, takerOrder.maker, makerAssetId, takerAssetId, takerFeeAmount);

        // necessary for stack too deep
        OrderFilledParams memory params = OrderFilledParams({
            orderHash: orderHash,
            maker: takerOrder.maker,
            taker: address(this),
            side: takerOrder.side,
            tokenId: takerOrder.tokenId,
            makerAmountFilled: making,
            takerAmountFilled: taking,
            fee: takerFeeAmount,
            builder: takerOrder.builder,
            metadata: takerOrder.metadata
        });

        _emitTakerFilledEvents(params);
    }

    /// @notice Settles a Taker order
    /// @dev Transfer proceeds from Exchange to order maker
    /// @dev Charge fee on Collateral proceeds if Sell, or on order maker Collateral if Buy
    function _settleTakerOrder(
        Side side,
        uint256 takingAmount,
        address maker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        uint256 feeAmount
    ) internal {
        // If SELL, fees are deducted from proceeds and transferred from the Exchange
        // If BUY, fees are transferred from the maker directly
        address feePayer = side == Side.BUY ? maker : address(this);

        uint256 proceeds = takingAmount;
        if (side == Side.SELL) {
            if (feeAmount > takingAmount) revert FeeExceedsProceeds();
            proceeds = takingAmount - feeAmount;
        }

        // Transfer order proceeds from the Exchange to the taker order maker
        _transfer(address(this), maker, takerAssetId, proceeds);

        // Charge the fee, if any
        _chargeFee(feePayer, feeAmount);

        // Refund any leftover tokens
        uint256 refund = _getBalance(makerAssetId);
        if (refund > 0) _transfer(address(this), maker, makerAssetId, refund);
    }

    function _settleMakerOrders(
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256[] memory makerFillAmounts,
        uint256[] memory makerFeeAmounts,
        uint256 maxFeeRate
    ) internal {
        uint256 length = makerOrders.length;
        uint256 i = 0;
        for (; i < length; ++i) {
            _settleMakerOrder(takerOrder, makerOrders[i], makerFillAmounts[i], makerFeeAmounts[i], maxFeeRate);
        }
    }

    /// @notice Settles a Maker order
    /// @param takerOrder   - The taker order
    /// @param makerOrder   - The maker order
    /// @param fillAmount   - The fill amount
    /// @param feeAmount    - The fee amount
    /// @param maxFeeRate   - The maximum fee rate allowed
    function _settleMakerOrder(
        Order memory takerOrder,
        Order memory makerOrder,
        uint256 fillAmount,
        uint256 feeAmount,
        uint256 maxFeeRate
    ) internal {
        MatchType matchType = _deriveMatchType(takerOrder, makerOrder);

        // Ensure taker order and maker order match
        _validateTakerAndMaker(takerOrder, makerOrder, matchType);

        uint256 making = fillAmount;
        (uint256 taking, bytes32 orderHash) = _performOrderChecks(makerOrder, making, feeAmount, maxFeeRate);

        (uint256 makerAssetId, uint256 takerAssetId) = _deriveAssetIds(makerOrder);

        _settleFacingExchange(
            making, taking, makerOrder.maker, makerAssetId, takerAssetId, makerOrder.side, matchType, feeAmount
        );

        // necessary for stack too deep
        OrderFilledParams memory params = OrderFilledParams({
            orderHash: orderHash,
            maker: makerOrder.maker,
            taker: takerOrder.maker,
            side: makerOrder.side,
            tokenId: makerOrder.tokenId,
            makerAmountFilled: making,
            takerAmountFilled: taking,
            fee: feeAmount,
            builder: makerOrder.builder,
            metadata: makerOrder.metadata
        });

        _emitOrderFilledEvent(params);
    }

    /// @notice Settle a maker order using the Exchange as the counterparty
    /// @param makingAmount - Amount to be filled in terms of maker amount
    /// @param takingAmount - Amount to be filled in terms of taker amount
    /// @param maker        - The order maker
    /// @param makerAssetId - The Token Id of the Asset to be sold
    /// @param takerAssetId - The Token Id of the Asset to be received
    /// @param matchType    - The match type
    /// @param feeAmount    - The fee charged to the Order maker
    function _settleFacingExchange(
        uint256 makingAmount,
        uint256 takingAmount,
        address maker,
        uint256 makerAssetId,
        uint256 takerAssetId,
        Side side,
        MatchType matchType,
        uint256 feeAmount
    ) internal {
        // Transfer making amount from maker to the Exchange
        _transfer(maker, address(this), makerAssetId, makingAmount);

        // Executes a match call based on match type
        _executeMatchCall(makingAmount, takingAmount, makerAssetId, takerAssetId, matchType);

        // Ensure match action generated enough tokens to fill the order
        if (_getBalance(takerAssetId) < takingAmount) revert TooLittleTokensReceived();

        // Determine the fee payer
        // If SELL, fees are deducted from proceeds and transferred from the Exchange
        // If BUY, fees are transferred from the maker directly
        address feePayer = side == Side.BUY ? maker : address(this);

        uint256 proceeds = takingAmount;
        if (side == Side.SELL) {
            if (feeAmount > takingAmount) revert FeeExceedsProceeds();
            proceeds = takingAmount - feeAmount;
        }

        // Transfer order proceeds from the Exchange to the order maker
        _transfer(address(this), maker, takerAssetId, proceeds);

        // Charge the fee, if any
        _chargeFee(feePayer, feeAmount);
    }

    function _emitTakerFilledEvents(OrderFilledParams memory params) internal {
        _emitOrderFilledEvent(params);

        emit OrdersMatched(
            params.orderHash,
            params.maker,
            params.side,
            params.tokenId,
            params.makerAmountFilled,
            params.takerAmountFilled
        );
    }

    function _emitOrderFilledEvent(OrderFilledParams memory params) internal {
        emit OrderFilled(
            params.orderHash,
            params.maker,
            params.taker,
            params.side,
            params.tokenId,
            params.makerAmountFilled,
            params.takerAmountFilled,
            params.fee,
            params.builder,
            params.metadata
        );
    }

    /// @notice Performs common order computations and validation
    /// 1) Validates the order taker
    /// 2) Computes the order hash
    /// 3) Validates the order
    /// 4) Computes taking amount
    /// 5) Validates fee against max fee rate
    /// 6) Updates the order status in storage
    /// @param order        - The order being prepared
    /// @param making       - The amount of the order being filled, in terms of maker amount
    /// @param fee          - The fee charged to the order by the operator
    /// @param maxFeeRate   - The maximum fee rate allowed in basis points
    function _performOrderChecks(Order memory order, uint256 making, uint256 fee, uint256 maxFeeRate)
        internal
        returns (uint256 takingAmount, bytes32 orderHash)
    {
        orderHash = hashOrder(order);

        // Validate order
        _validateOrder(orderHash, order);

        // Calculate taking amount
        takingAmount = CalculatorHelper.calculateTakingAmount(making, order.makerAmount, order.takerAmount);

        // Validate fee against max fee rate
        uint256 cashValue = order.side == Side.BUY ? making : takingAmount;
        validateFeeWithMaxFeeRate(fee, cashValue, maxFeeRate);

        // Update the order status in storage
        _updateOrderStatus(orderHash, order, making);
    }

    function _deriveMatchType(Order memory takerOrder, Order memory makerOrder) internal pure returns (MatchType) {
        if (takerOrder.side == Side.BUY && makerOrder.side == Side.BUY) return MatchType.MINT;
        if (takerOrder.side == Side.SELL && makerOrder.side == Side.SELL) return MatchType.MERGE;
        return MatchType.COMPLEMENTARY;
    }

    function _deriveAssetIds(Order memory order) internal pure returns (uint256 makerAssetId, uint256 takerAssetId) {
        if (order.side == Side.BUY) return (0, order.tokenId);
        return (order.tokenId, 0);
    }

    /// @notice Executes a CTF call to match orders by minting new Outcome tokens
    /// or merging Outcome tokens into collateral.
    /// @param makingAmount - Amount to be filled in terms of maker amount
    /// @param takingAmount - Amount to be filled in terms of taker amount
    /// @param makerAssetId - The Token Id of the Asset to be sold
    /// @param takerAssetId - The Token Id of the Asset to be received
    /// @param matchType    - The match type
    function _executeMatchCall(
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 makerAssetId,
        uint256 takerAssetId,
        MatchType matchType
    ) internal {
        if (matchType == MatchType.COMPLEMENTARY) {
            // Indicates a buy vs sell order
            // no match action needed
            return;
        }
        if (matchType == MatchType.MINT) {
            // Indicates matching 2 buy orders
            // Mint new Outcome tokens using Exchange collateral balance and fill buys
            return _mint(getConditionId(takerAssetId), takingAmount);
        }
        if (matchType == MatchType.MERGE) {
            // Indicates matching 2 sell orders
            // Merge the Exchange Outcome token balance into collateral and fill sells
            return _merge(getConditionId(makerAssetId), makingAmount);
        }
    }

    /// @notice Ensures the taker and maker orders can be matched against each other
    /// @param takerOrder   - The taker order
    /// @param makerOrder   - The maker order
    function _validateTakerAndMaker(Order memory takerOrder, Order memory makerOrder, MatchType matchType)
        internal
        view
    {
        if (!CalculatorHelper.isCrossing(takerOrder, makerOrder)) revert NotCrossing();

        // Ensure orders match
        if (matchType == MatchType.COMPLEMENTARY) {
            if (takerOrder.tokenId != makerOrder.tokenId) revert MismatchedTokenIds();
        } else {
            // both bids or both asks
            validateComplement(takerOrder.tokenId, makerOrder.tokenId);
        }
    }

    function _chargeFee(address payer, uint256 fee) internal {
        // Charge fee to the payer if any
        if (fee > 0) {
            address receiver = getFeeReceiver();
            _transfer(payer, receiver, 0, fee);
            emit FeeCharged(receiver, fee);
        }
    }

    function _updateOrderStatus(bytes32 orderHash, Order memory order, uint256 makingAmount)
        internal
        returns (uint256 remaining)
    {
        OrderStatus storage status = orderStatus[orderHash];
        // Fetch remaining amount from storage
        remaining = status.remaining;

        // Update remaining if the order is new/has not been filled
        remaining = remaining == 0 ? order.makerAmount : remaining;

        // Throw if the makingAmount(amount to be filled) is greater than the amount available
        if (makingAmount > remaining) revert MakingGtRemaining();

        // Update remaining using the makingAmount
        remaining = remaining - makingAmount;

        // If order is completely filled, update filled in storage
        if (remaining == 0) status.filled = true;

        // Update remaining in storage
        status.remaining = remaining;
    }

    function _updateTakingWithSurplus(uint256 minimumAmount, uint256 tokenId) internal returns (uint256) {
        uint256 actualAmount = _getBalance(tokenId);
        if (actualAmount < minimumAmount) revert TooLittleTokensReceived();
        return actualAmount;
    }
}
