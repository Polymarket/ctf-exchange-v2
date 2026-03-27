// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

import { OwnableRoles } from "@solady/src/auth/OwnableRoles.sol";

import { CollateralErrors } from "./CollateralErrors.sol";

/// @title PausableEvents
/// @author Polymarket
/// @notice Events emitted by the Pausable contract.
abstract contract PausableEvents {
    /// @notice Emitted when wrapping/unwrapping is paused.
    /// @param asset The paused asset address.
    event Paused(address indexed asset);

    /// @notice Emitted when wrapping/unwrapping is unpaused.
    /// @param asset The unpaused asset address.
    event Unpaused(address indexed asset);
}

/// @title Pausable
/// @author Polymarket
/// @notice Per-asset pause functionality for collateral operations.
abstract contract Pausable is OwnableRoles, CollateralErrors, PausableEvents {
    /*--------------------------------------------------------------
                                 STATE
    --------------------------------------------------------------*/

    /// @notice Whether an asset is currently paused.
    mapping(address => bool) public paused;

    /*--------------------------------------------------------------
                               CONSTANTS
    --------------------------------------------------------------*/

    /// @dev Admin role for pause/unpause operations.
    uint256 internal constant ADMIN_ROLE = _ROLE_0;

    /*--------------------------------------------------------------
                               MODIFIERS
    --------------------------------------------------------------*/

    /// @dev Reverts if the given asset is paused.
    modifier onlyUnpaused(address _asset) {
        require(!paused[_asset], OnlyUnpaused());
        _;
    }

    /*--------------------------------------------------------------
                               ONLY ADMIN
    --------------------------------------------------------------*/

    /// @notice Pauses the wrapping/unwrapping of a supported asset
    /// @param _asset The asset to pause
    /// @dev The caller must have the ADMIN_ROLE role
    function pause(address _asset) external onlyRoles(ADMIN_ROLE) {
        paused[_asset] = true;

        emit Paused(_asset);
    }

    /// @notice Unpauses the wrapping/unwrapping of a supported asset
    /// @param _asset The asset to unpause
    /// @dev The caller must have the ADMIN_ROLE role
    function unpause(address _asset) external onlyRoles(ADMIN_ROLE) {
        paused[_asset] = false;

        emit Unpaused(_asset);
    }
}
