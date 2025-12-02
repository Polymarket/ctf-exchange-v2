// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

interface IFeesEE {
    error MaxFeeExceeded();

    /// @notice Emitted when a fee is charged
    event FeeCharged(address indexed receiver, uint256 amount);

    /// @notice Emitted when the fee receiver is updated
    event FeeReceiverUpdated(address indexed feeReceiver);
}

abstract contract IFees is IFeesEE {
    function validateOrderFee(uint256 maxFillFee, uint256 fee) public pure virtual;

    function getFeeReceiver() public view virtual returns (address);

    function _setFeeReceiver(address receiver) internal virtual;
}
