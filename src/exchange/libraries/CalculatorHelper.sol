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
        if (makerAmount == 0) return 0;
        return makingAmount * takerAmount / makerAmount;
    }

    function calculatePrice(Order memory order) internal pure returns (uint256) {
        return _calculatePrice(order.makerAmount, order.takerAmount, order.side);
    }

    function _calculatePrice(uint256 makerAmount, uint256 takerAmount, Side side) internal pure returns (uint256) {
        // If side is 0, (buy) swap makerAmount and takerAmount using xor involution: (A xor B xor B) = A
        // 1. compute a mask, 0 if side is BUY, 0xff..ff if side is SELL
        // 2. compute the "swap" makerAmount XOR takerAmount masked by the mask in step 1
        // The above is zero if side is BUY
        // 3. xor(makerAmount, swap) / xor(takerAmount, swap), if side is BUY, this is makerAmount / takerAmount
        // and the opposite if side is SELL
        uint256 result;
        assembly {
            let mask := sub(0, side)
            let swap := and(xor(makerAmount, takerAmount), mask)
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
