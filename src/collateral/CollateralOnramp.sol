// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { OwnableRoles } from "lib/solady/src/auth/OwnableRoles.sol";
import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";
import { Pausable } from "./abstract/Pausable.sol";

import { CollateralToken } from "./CollateralToken.sol";

/// @title CollateralOnramp
/// @author Polymarket
/// @notice Permissionless onramp for the PolymarketCollateralToken
/// @notice ROLE_0: Admin
contract CollateralOnramp is OwnableRoles, CollateralErrors, Pausable {
    using SafeTransferLib for address;

    /*--------------------------------------------------------------
                                 STATE
    --------------------------------------------------------------*/

    address public immutable collateralToken;

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    constructor(address _owner, address _admin, address _collateralToken) {
        collateralToken = _collateralToken;

        _initializeOwner(_owner);
        _grantRoles(_admin, _ROLE_0);
    }

    /*--------------------------------------------------------------
                                EXTERNAL
    --------------------------------------------------------------*/

    /// @notice Wraps a supported asset into the collateral token
    /// @param _asset The asset to wrap
    /// @param _to The address to wrap the asset to
    /// @param _amount The amount of asset to wrap
    /// @dev The asset must not be paused
    function wrap(address _asset, address _to, uint256 _amount) external onlyUnpaused(_asset) {
        _asset.safeTransferFrom(msg.sender, collateralToken, _amount);
        CollateralToken(collateralToken).wrap(_asset, _to, _amount, address(0), "");
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
}
