// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { OwnableRoles } from "lib/solady/src/auth/OwnableRoles.sol";
import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";

import { CollateralToken } from "./CollateralToken.sol";

/// @title CollateralOfframp
/// @author Polymarket
/// @notice Permissionless offramp for a single asset from the PolymarketCollateralToken
/// @notice ROLE_0: Admin
contract CollateralOfframp is OwnableRoles, CollateralErrors {
    using SafeTransferLib for address;

    /*--------------------------------------------------------------
                                 EVENTS
    --------------------------------------------------------------*/

    event Paused();
    event Unpaused();

    /*--------------------------------------------------------------
                                 STATE
    --------------------------------------------------------------*/

    address public immutable collateralToken;
    address public immutable asset;

    bool public paused;

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    constructor(address _owner, address _admin, address _collateralToken, address _asset) {
        collateralToken = _collateralToken;
        asset = _asset;

        _initializeOwner(_owner);
        _grantRoles(_admin, _ROLE_0);
    }

    /*--------------------------------------------------------------
                                EXTERNAL
    --------------------------------------------------------------*/

    /// @notice Unwraps the asset from the collateral token
    /// @param _to The address to unwrap the asset to
    /// @param _amount The amount of asset to unwrap
    /// @dev The contract must not be paused
    function unwrap(address _to, uint256 _amount) external {
        require(!paused, OnlyUnpaused());
        collateralToken.safeTransferFrom(msg.sender, collateralToken, _amount);
        CollateralToken(collateralToken).unwrap(asset, _to, _amount, address(0), "");
    }

    /*--------------------------------------------------------------
                               ONLY ADMIN
    --------------------------------------------------------------*/

    /// @notice Adds a new admin to the contract
    /// @param _admin The address of the new admin
    function addAdmin(address _admin) external onlyRoles(_ROLE_0) {
        _grantRoles(_admin, _ROLE_0);
    }

    /// @notice Removes an admin from the contract
    /// @param _admin The address of the admin to remove
    function removeAdmin(address _admin) external onlyRoles(_ROLE_0) {
        _removeRoles(_admin, _ROLE_0);
    }

    /// @notice Pauses unwrapping
    function pause() external onlyRoles(_ROLE_0) {
        paused = true;
        emit Paused();
    }

    /// @notice Unpauses unwrapping
    function unpause() external onlyRoles(_ROLE_0) {
        paused = false;
        emit Unpaused();
    }
}
