// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { IUserPausable } from "../interfaces/IUserPausable.sol";

/// @title UserPausable
/// @notice Mixin to allow users to pause and unpause their accounts
/// @author Polymarket
abstract contract UserPausable is IUserPausable {
    /// @notice The number of blocks after which a user's pause becomes effective
    uint256 public userPauseBlockInterval = 100;

    /// @notice A mapping of users to the block number at which their pause becomes effective
    mapping(address => uint256) public userPausedBlockAt;

    /// @notice Checks if a user is currently paused
    /// @param user - The user address to check
    function isUserPaused(address user) public view override returns (bool) {
        uint256 blockPausedAt = userPausedBlockAt[user];
        return blockPausedAt > 0 && block.number > blockPausedAt;
    }

    /// @notice Allows a user to pause their account
    function pauseUser() external override {
        uint256 blockPausedAt = block.number + userPauseBlockInterval;
        userPausedBlockAt[msg.sender] = blockPausedAt;
        emit UserPaused(msg.sender, blockPausedAt);
    }

    /// @notice Allows a user to unpause their account
    function unpauseUser() external override {
        userPausedBlockAt[msg.sender] = 0;
        emit UserUnpaused(msg.sender);
    }

    /// @notice Sets the block interval after which a user's pause becomes effective
    /// @param blockInterval - The new block interval
    function _setUserPauseBlockInterval(uint256 blockInterval) internal {
        uint256 oldInterval = userPauseBlockInterval;
        userPauseBlockInterval = blockInterval;
        emit UserPauseBlockIntervalUpdated(oldInterval, blockInterval);
    }
}
