// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { OwnableRoles } from "lib/solady/src/auth/OwnableRoles.sol";
import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";

import { CollateralToken } from "./CollateralToken.sol";

/// @title CollateralOnramp
/// @author Polymarket
/// @notice Permissionless onramp for a single asset into the PolymarketCollateralToken
/// @notice ROLE_0: Admin
contract CollateralOnramp is OwnableRoles, CollateralErrors {
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

    /// @notice Wraps the asset into the collateral token
    /// @param _to The address to wrap the asset to
    /// @param _amount The amount of asset to wrap
    /// @dev The contract must not be paused
    function wrap(address _to, uint256 _amount) external {
        require(!paused, OnlyUnpaused());
        asset.safeTransferFrom(msg.sender, collateralToken, _amount);
        CollateralToken(collateralToken).wrap(asset, _to, _amount, address(0), "");
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

    /// @notice Pauses wrapping
    function pause() external onlyRoles(_ROLE_0) {
        paused = true;
        emit Paused();
    }

    /// @notice Unpauses wrapping
    function unpause() external onlyRoles(_ROLE_0) {
        paused = false;
        emit Unpaused();
    }
}
