// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Test } from "lib/forge-std/src/Test.sol";

import { CalculatorHelper } from "src/exchange/libraries/CalculatorHelper.sol";

contract CalculatorHelperTest is Test {
    function test_CalculatorHelper_FuzzCalculateTakingAmount(uint64 making, uint128 makerAmount, uint128 takerAmount)
        public
        pure
    {
        vm.assume(makerAmount > 0 && making <= makerAmount);
        // Explicitly cast to 256 to avoid overflows
        uint256 expected = making * uint256(takerAmount) / uint256(makerAmount);
        assertEq(CalculatorHelper.calculateTakingAmount(making, makerAmount, takerAmount), expected);
    }
}
