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
        uint256 priceA = _calculatePrice(a.makerAmount, a.takerAmount, a.side);
        uint256 priceB = _calculatePrice(b.makerAmount, b.takerAmount, b.side);

        if (a.side == Side.SELL && b.side == Side.SELL) {
            if (a.takerAmount == 0) return priceB < ONE;
            if (b.takerAmount == 0) return priceA < ONE;
        }

        if (a.takerAmount == 0 || b.takerAmount == 0) return true;
        return _isCrossing(priceA, priceB, a.side, b.side);
    }

    function _isCrossing(uint256 priceA, uint256 priceB, Side sideA, Side sideB) internal pure returns (bool) {
        bool result;
        assembly ("memory-safe") {
            switch eq(sideA, sideB)
            case 0 {
                // sideA and sideB are different, complementary order
                // if A is BUY, priceA must be >= priceB
                // if A is ASK, priceA must be <= priceB
                // We have a simple XOR swap to do
                let swap := mul(xor(priceA, priceB), sideA)
                result := iszero(lt(xor(priceA, swap), xor(priceB, swap)))
            }
            case 1 {
                // sideA and sideB are the same
                // if BUY, sum must be >= 1 to merge (iszero(lessThan))
                // if SELL, sum must be <= 1 to split (iszero(greaterThan))
                let sum := add(priceA, priceB)
                let lessThan := lt(sum, ONE)
                let greaterThan := gt(sum, ONE)

                // We only want to swap lessThan for greaterThan if sideA is 1 (SELL)
                let swap := mul(xor(lessThan, greaterThan), sideA)
                result := iszero(xor(lessThan, swap))
            }
        }
        return result;
    }
}
