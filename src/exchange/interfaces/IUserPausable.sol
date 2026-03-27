// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

interface IUserPausableEE {
    error UserIsPaused();
    error UserAlreadyPaused();
    error ExceedsMaxPauseInterval();

    /// @notice Emitted when the user pause block interval is updated
    event UserPauseBlockIntervalUpdated(uint256 oldInterval, uint256 newInterval);

    /// @notice Emitted when a user pauses their account
    event UserPaused(address indexed user, uint256 effectivePauseBlock);

    /// @notice Emitted when a user unpauses their account
    event UserUnpaused(address indexed user);
}

abstract contract IUserPausable is IUserPausableEE {
    function isUserPaused(address usr) public view virtual returns (bool);

    function pauseUser() external virtual;

    function unpauseUser() external virtual;
}

