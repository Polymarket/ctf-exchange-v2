// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IFees } from "../interfaces/IFees.sol";

abstract contract Fees is IFees {
    /// @notice Denominator for basis points calculations
    uint256 internal constant BPS_DENOMINATOR = 10_000;

    /// @notice Maximum allowed fee rate in basis points
    uint256 internal constant MAX_FEE_RATE_BPS_CAP = 10_000; // 100%

    /// @notice The address that receives fees
    address internal feeReceiver;

    /// @notice The maximum fee rate allowed in basis points
    uint256 internal maxFeeRateBps = 1000; // Default to 10%

    constructor(address _feeReceiver) {
        feeReceiver = _feeReceiver;
    }

    /// @notice Returns the current fee receiver address
    function getFeeReceiver() public view override returns (address) {
        return feeReceiver;
    }

    /// @notice Returns the current max fee rate in basis points
    function getMaxFeeRate() public view override returns (uint256) {
        return maxFeeRateBps;
    }

    /// @notice Validates that the fee does not exceed the maximum allowed rate
    /// @param fee       - The fee amount being charged, denominated in collateral
    /// @param cashValue - The value of the trade, denominated in collateral
    function validateFee(uint256 fee, uint256 cashValue) public view override {
        if (maxFeeRateBps == 0) return; // No limit enforced if rate is 0
        if (cashValue == 0) return;
        uint256 maxAllowedFee = (cashValue * maxFeeRateBps) / BPS_DENOMINATOR;
        if (fee > maxAllowedFee) revert FeeExceedsMaxRate();
    }

    function _setFeeReceiver(address _feeReceiver) internal override {
        feeReceiver = _feeReceiver;
        emit FeeReceiverUpdated(_feeReceiver);
    }

    /// @notice Sets the maximum fee rate in basis points
    /// @param _maxFeeRateBps - The new max fee rate in bps (e.g., 500 = 5%), max (99%)
    function _setMaxFeeRate(uint256 _maxFeeRateBps) internal override {
        if (_maxFeeRateBps >= MAX_FEE_RATE_BPS_CAP) revert MaxFeeRateExceedsCeiling();
        maxFeeRateBps = _maxFeeRateBps;
        emit MaxFeeRateUpdated(_maxFeeRateBps);
    }
}
