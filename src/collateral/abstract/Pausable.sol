// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { OwnableRoles } from "lib/solady/src/auth/OwnableRoles.sol";

import { CollateralErrors } from "./CollateralErrors.sol";

abstract contract PausableEvents {
    event Paused(address indexed asset);
    event Unpaused(address indexed asset);
}

/// @title Pausable
/// @author Polymarket
abstract contract Pausable is OwnableRoles, CollateralErrors, PausableEvents {
    mapping(address => bool) public paused;

    modifier onlyUnpaused(address _asset) {
        require(!paused[_asset], OnlyUnpaused());
        _;
    }

    /// @notice Pauses the wrapping/unwrapping of a supported asset
    /// @param _asset The asset to pause
    /// @dev The caller must have the ROLE_0 role
    function pause(address _asset) external onlyRoles(_ROLE_0) {
        paused[_asset] = true;

        emit Paused(_asset);
    }

    /// @notice Unpauses the wrapping/unwrapping of a supported asset
    /// @param _asset The asset to unpause
    /// @dev The caller must have the ROLE_0 role
    function unpause(address _asset) external onlyRoles(_ROLE_0) {
        paused[_asset] = false;

        emit Unpaused(_asset);
    }
}
