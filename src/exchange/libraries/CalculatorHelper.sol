// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

library CalculatorHelper {
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
}
