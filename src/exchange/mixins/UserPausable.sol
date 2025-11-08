// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IUserPausable } from "../interfaces/IUserPausable.sol";

/// @title UserPausable
/// @notice Mixin to allow users to pause and unpause their accounts
/// @author Polymarket
abstract contract UserPausable is IUserPausable {
    mapping(address => bool) internal _paused;

    function isPaused(address usr) public override view returns (bool) {
        return _paused[usr];
    }

    /// @notice Allows a user to pause their account
    function pauseUser() external override {
        _paused[msg.sender] = true;
        emit UserPaused(msg.sender);
    }

    function unpauseUser() external override {
        _paused[msg.sender] = false;
        emit UserUnpaused(msg.sender);
    }
}
