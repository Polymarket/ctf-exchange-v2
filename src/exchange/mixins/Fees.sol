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

    /// @notice Returns the maximum fee rate for an order
    /// @param maxFee       - The maximum fee allowed for the order, signed by the user
    /// @param operatorFee  - The fee being charged to the order, by the operator
    function validateOrderFee(uint256 maxFee, uint256 operatorFee) public pure override {
        if (operatorFee > maxFee) revert MaxFeeExceeded();
    }

    function _setFeeReceiver(address _feeReceiver) internal override {
        feeReceiver = _feeReceiver;
        emit FeeReceiverUpdated(_feeReceiver);
    }
}
