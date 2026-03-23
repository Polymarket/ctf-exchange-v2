// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Test } from "@forge-std/src/Test.sol";

import { CalculatorHelper } from "@ctf-exchange-v2/src/exchange/libraries/CalculatorHelper.sol";

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

    function test_CalculatorHelper_revert_CalculateTakingAmountOverflow() public {
        // makingAmount * takerAmount overflows uint256
        uint256 makingAmount = type(uint256).max;
        uint256 takerAmount = 2;
        uint256 makerAmount = 1;
        vm.expectRevert();
        this.externalCalculateTakingAmount(makingAmount, makerAmount, takerAmount);
    }

    function externalCalculateTakingAmount(uint256 makingAmount, uint256 makerAmount, uint256 takerAmount)
        external
        pure
        returns (uint256)
    {
        return CalculatorHelper.calculateTakingAmount(makingAmount, makerAmount, takerAmount);
    }
}
