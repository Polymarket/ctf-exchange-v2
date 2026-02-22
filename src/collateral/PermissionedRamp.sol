// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { OwnableRoles } from "lib/solady/src/auth/OwnableRoles.sol";
import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";
import { Pausable } from "./abstract/Pausable.sol";

import { CollateralToken } from "./CollateralToken.sol";

/// @title PermissionedRamp
/// @author Polymarket
/// @notice Permissioned wrap/unwrap for the PolymarketCollateralToken
/// @notice ROLE_0: Admin
/// @notice ROLE_1: Authorized caller
contract PermissionedRamp is OwnableRoles, CollateralErrors, Pausable {
    using SafeTransferLib for address;

    /*--------------------------------------------------------------
                                 STATE
    --------------------------------------------------------------*/

    address public immutable collateralToken;

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    constructor(address _owner, address _collateralToken) {
        collateralToken = _collateralToken;

        _initializeOwner(_owner);
    }

    /*--------------------------------------------------------------
                                EXTERNAL
    --------------------------------------------------------------*/

    /// @notice Wraps a supported asset into the collateral token
    /// @param _asset The asset to wrap
    /// @param _to The address to wrap the asset to
    /// @param _amount The amount of asset to wrap
    function wrap(address _asset, address _to, uint256 _amount) external onlyRoles(_ROLE_1) onlyUnpaused(_asset) {
        _asset.safeTransferFrom(msg.sender, collateralToken, _amount);
        CollateralToken(collateralToken).wrap(_asset, _to, _amount, address(0), "");
    }

    /// @notice Unwraps a supported asset from the collateral token
    /// @param _asset The asset to unwrap
    /// @param _to The address to unwrap the asset to
    /// @param _amount The amount of asset to unwrap
    function unwrap(address _asset, address _to, uint256 _amount) external onlyRoles(_ROLE_1) onlyUnpaused(_asset) {
        collateralToken.safeTransferFrom(msg.sender, collateralToken, _amount);
        CollateralToken(collateralToken).unwrap(_asset, _to, _amount, address(0), "");
    }

    /*--------------------------------------------------------------
                               ONLY ADMIN
    --------------------------------------------------------------*/

    /// @notice Adds an authorized caller
    /// @param _caller The address to authorize
    function addCaller(address _caller) external onlyRoles(_ROLE_0) {
        _grantRoles(_caller, _ROLE_1);
    }

    /// @notice Removes an authorized caller
    /// @param _caller The address to deauthorize
    function removeCaller(address _caller) external onlyRoles(_ROLE_0) {
        _removeRoles(_caller, _ROLE_1);
    }
}
