// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { IFees } from "../interfaces/IFees.sol";

abstract contract Fees is IFees {
    address internal feeReceiver;

    constructor(address _feeReceiver) {
        feeReceiver = _feeReceiver;
    }

    /// @notice Returns the current fee receiver address
    function getFeeReceiver() public view override returns (address) {
        return feeReceiver;
    }

    /// @notice Validates that the operator fee does not exceed the maximum fee implied by the fill amount
    /// @param maxFillFee   - The maximum fee allowed for the order, implied by the fill amount
    /// @param operatorFee  - The fee being charged to the order, by the operator
    function validateOrderFee(uint256 maxFillFee, uint256 operatorFee) public pure override {
        if (operatorFee > maxFillFee) revert MaxFeeExceeded();
    }

    function _setFeeReceiver(address _feeReceiver) internal override {
        feeReceiver = _feeReceiver;
        emit FeeReceiverUpdated(_feeReceiver);
    }
}
