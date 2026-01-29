// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Order, Side } from "../libraries/Structs.sol";

library CalculatorHelper {
    uint256 internal constant ONE = 10 ** 18;

    uint256 internal constant BPS_DIVISOR = 10_000;

    function calculateTakingAmount(uint256 makingAmount, uint256 makerAmount, uint256 takerAmount)
        internal
        pure
        returns (uint256)
    {
        // division by zero in the EVM returns 0
        uint256 result;
        assembly ("memory-safe") {
            result := div(mul(makingAmount, takerAmount), makerAmount)
        }
        return result;
    }

    function calculatePrice(Order memory order) internal pure returns (uint256) {
        return _calculatePrice(order.makerAmount, order.takerAmount, order.side);
    }

    function _calculatePrice(uint256 makerAmount, uint256 takerAmount, Side side) internal pure returns (uint256) {
        // If side is 0, (buy) swap makerAmount and takerAmount using xor involution: (A xor B xor B) = A
        // 1. compute the "swap" makerAmount XOR takerAmount if side is SELL, otherwise zero
        // 2. xor(makerAmount, swap) / xor(takerAmount, swap), if side is BUY, this is makerAmount / takerAmount
        // and the opposite if side is SELL
        uint256 result;
        assembly ("memory-safe") {
            let swap := mul(xor(makerAmount, takerAmount), side)
            result := div(mul(xor(makerAmount, swap), ONE), xor(takerAmount, swap))
        }
        return result;
    }

    function isCrossing(Order memory a, Order memory b) internal pure returns (bool) {
        uint256 priceA = calculatePrice(a);
        uint256 priceB = calculatePrice(b);

        if (a.side == Side.SELL && b.side == Side.SELL) {
            if (a.takerAmount == 0) return priceB < ONE;
            if (b.takerAmount == 0) return priceA < ONE;
        }

        if (a.takerAmount == 0 || b.takerAmount == 0) return true;
        return _isCrossing(priceA, priceB, a.side, b.side);
    }

    function _isCrossing(uint256 priceA, uint256 priceB, Side sideA, Side sideB) internal pure returns (bool) {
        if (sideA == Side.BUY) {
            if (sideB == Side.BUY) {
                // if a and b are bids
                return priceA + priceB >= ONE;
            }
            // if a is bid and b is ask
            return priceA >= priceB;
        }
        if (sideB == Side.BUY) {
            // if a is ask and b is bid
            return priceB >= priceA;
        }
        // if a and b are asks
        return priceA + priceB <= ONE;
    }
}
