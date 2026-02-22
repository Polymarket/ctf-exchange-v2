// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { OwnableRoles } from "lib/solady/src/auth/OwnableRoles.sol";
import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";
import { Pausable } from "./abstract/Pausable.sol";

import { CollateralToken } from "./CollateralToken.sol";

/// @title CollateralOnramp
/// @author Polymarket
/// @notice Permissionless onramp for a single asset into the PolymarketCollateralToken
/// @notice ROLE_0: Admin
contract CollateralOnramp is OwnableRoles, CollateralErrors, Pausable {
    using SafeTransferLib for address;

    /*--------------------------------------------------------------
                                 STATE
    --------------------------------------------------------------*/

    address public immutable collateralToken;
    address public immutable asset;

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    constructor(address _owner, address _collateralToken, address _asset) {
        collateralToken = _collateralToken;
        asset = _asset;

        _initializeOwner(_owner);
    }

    /*--------------------------------------------------------------
                                EXTERNAL
    --------------------------------------------------------------*/

    /// @notice Wraps the asset into the collateral token
    /// @param _to The address to wrap the asset to
    /// @param _amount The amount of asset to wrap
    /// @dev The asset must not be paused
    function wrap(address _to, uint256 _amount) external onlyUnpaused(asset) {
        asset.safeTransferFrom(msg.sender, collateralToken, _amount);
        CollateralToken(collateralToken).wrap(asset, _to, _amount, address(0), "");
    }
}
