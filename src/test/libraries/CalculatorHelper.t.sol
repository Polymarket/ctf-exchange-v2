// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { Test } from "lib/forge-std/src/Test.sol";

import { CalculatorHelper } from "src/exchange/libraries/CalculatorHelper.sol";
import { Side } from "src/exchange/libraries/Structs.sol";

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

    function test_CalculatorHelper_FuzzCalculatePrice(uint128 makerAmount, uint128 takerAmount, uint8 sideInt)
        public
        pure
    {
        vm.assume(sideInt <= 1);
        Side side = Side(sideInt);
        // Asserts not needed, test checks that we can calculate price safely without unexpected reverts

        CalculatorHelper._calculatePrice(makerAmount, takerAmount, side);
    }

    function test_CalculatorHelper_FuzzIsCrossing(
        uint128 makerAmountA,
        uint128 takerAmountA,
        uint8 sideIntA,
        uint128 makerAmountB,
        uint128 takerAmountB,
        uint8 sideIntB
    ) public pure {
        vm.assume(sideIntA <= 1 && sideIntB <= 1);
        Side sideA = Side(sideIntA);
        Side sideB = Side(sideIntB);
        uint256 priceA = CalculatorHelper._calculatePrice(makerAmountA, takerAmountA, sideA);
        uint256 priceB = CalculatorHelper._calculatePrice(makerAmountB, takerAmountB, sideB);

        // Asserts not needed, test checks that we can check isCrossing safely without unexpected reverts
        CalculatorHelper._isCrossing(priceA, priceB, sideA, sideB);
    }
}
