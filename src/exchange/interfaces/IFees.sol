// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

interface IFeesEE {
    /// @notice Thrown when fee exceeds the maximum allowed rate
    error FeeExceedsMaxRate();

    /// @notice Thrown when setting a fee rate above 100%
    error MaxFeeRateExceedsCeiling();

    /// @notice Emitted when a fee is charged
    event FeeCharged(address indexed receiver, uint256 amount);

    /// @notice Emitted when the fee receiver is updated
    event FeeReceiverUpdated(address indexed feeReceiver);

    /// @notice Emitted when the max fee rate is updated
    event MaxFeeRateUpdated(uint256 maxFeeRate);
}

abstract contract IFees is IFeesEE {
    function getFeeReceiver() public view virtual returns (address);

    function getMaxFeeRate() public view virtual returns (uint256);

    function validateFee(uint256 fee, uint256 cashValue) public view virtual;

    function _validateFeeWithMaxFeeRate(uint256 fee, uint256 cashValue, uint256 maxFeeRate) internal pure virtual;

    function _setFeeReceiver(address receiver) internal virtual;

    function _setMaxFeeRate(uint256 rate) internal virtual;
}
