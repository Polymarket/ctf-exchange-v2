// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

library CalculatorHelper {
    function calculateTakingAmount(uint256 makingAmount, uint256 makerAmount, uint256 takerAmount)
        internal
        pure
        returns (uint256)
    {
        return (makingAmount * takerAmount) / makerAmount;
    }
}
