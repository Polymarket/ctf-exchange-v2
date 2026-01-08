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

    function _setFeeReceiver(address _feeReceiver) internal override {
        feeReceiver = _feeReceiver;
        emit FeeReceiverUpdated(_feeReceiver);
    }
}
