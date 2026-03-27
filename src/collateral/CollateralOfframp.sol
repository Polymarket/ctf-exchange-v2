// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

import { OwnableRoles } from "@solady/src/auth/OwnableRoles.sol";
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";
import { Pausable } from "./abstract/Pausable.sol";

import { CollateralToken } from "./CollateralToken.sol";

/// @title CollateralOfframp
/// @author Polymarket
/// @notice Offramp for the PolymarketCollateralToken
/// @notice ADMIN_ROLE: Admin
contract CollateralOfframp is OwnableRoles, CollateralErrors, Pausable {
    using SafeTransferLib for address;

    /*--------------------------------------------------------------
                                 STATE
    --------------------------------------------------------------*/

    /// @notice The collateral token address.
    address public immutable COLLATERAL_TOKEN;

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    /// @notice Deploys the offramp contract.
    /// @param _owner The contract owner.
    /// @param _admin The initial admin address.
    /// @param _collateralToken The collateral token address.
    constructor(address _owner, address _admin, address _collateralToken) {
        COLLATERAL_TOKEN = _collateralToken;

        _initializeOwner(_owner);
        _grantRoles(_admin, ADMIN_ROLE);
    }

    /*--------------------------------------------------------------
                                EXTERNAL
    --------------------------------------------------------------*/

    /// @notice Unwraps a supported asset from the collateral token
    /// @param _asset The asset to unwrap
    /// @param _to The address to unwrap the asset to
    /// @param _amount The amount of asset to unwrap
    /// @dev The asset must not be paused
    function unwrap(address _asset, address _to, uint256 _amount) external onlyUnpaused(_asset) {
        COLLATERAL_TOKEN.safeTransferFrom(msg.sender, COLLATERAL_TOKEN, _amount);
        // forgefmt: disable-next-item
        CollateralToken(COLLATERAL_TOKEN).unwrap({
            _asset: _asset,
            _to: _to,
            _amount: _amount,
            _callbackReceiver: address(0),
            _data: ""
        });
    }

    /*--------------------------------------------------------------
                               ONLY ADMIN
    --------------------------------------------------------------*/

    /// @notice Adds a new admin to the contract
    /// @param _admin The address of the new admin
    function addAdmin(address _admin) external onlyRoles(ADMIN_ROLE) {
        _grantRoles(_admin, ADMIN_ROLE);
    }

    /// @notice Removes an admin from the contract
    /// @param _admin The address of the admin to remove
    function removeAdmin(address _admin) external onlyRoles(ADMIN_ROLE) {
        _removeRoles(_admin, ADMIN_ROLE);
    }
}
