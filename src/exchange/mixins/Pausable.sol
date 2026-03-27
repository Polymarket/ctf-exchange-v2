// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

import { IPausable } from "../interfaces/IPausable.sol";

abstract contract Pausable is IPausable {
    bool public paused = false;

    modifier notPaused() {
        require(!paused, Paused());
        _;
    }

    function _pauseTrading() internal override {
        paused = true;
        emit TradingPaused(msg.sender);
    }

    function _unpauseTrading() internal override {
        paused = false;
        emit TradingUnpaused(msg.sender);
    }
}
