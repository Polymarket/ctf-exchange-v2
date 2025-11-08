// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IUserPausableEE {
    error UserIsPaused();

    /// @notice Emitted when a user pauses their account
    event UserPaused(address indexed usr);

    /// @notice Emitted when a user unpauses their account
    event UserUnpaused(address indexed usr);
}

abstract contract IUserPausable is IUserPausableEE {
    function isPaused(address usr) public view virtual returns (bool);

    function pauseUser() external virtual;

    function unpauseUser() external virtual;
}

