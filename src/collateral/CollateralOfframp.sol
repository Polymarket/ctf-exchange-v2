// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { OwnableRoles } from "lib/solady/src/auth/OwnableRoles.sol";
import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";
import { Pausable } from "./abstract/Pausable.sol";

import { CollateralToken } from "./CollateralToken.sol";

/// @title CollateralOfframp
/// @author Polymarket
/// @notice Offramp for the PolymarketCollateralToken
/// @notice ROLE_0: Admin
contract CollateralOfframp is OwnableRoles, CollateralErrors, Pausable {
    using SafeTransferLib for address;

    address public immutable collateralToken;

    constructor(address _owner, address _collateralToken) {
        collateralToken = _collateralToken;

        _initializeOwner(_owner);
    }

    /// @notice Unwraps a supported asset from the collateral token
    /// @param _asset The asset to unwrap
    /// @param _to The address to unwrap the asset to
    /// @param _amount The amount of asset to unwrap
    /// @dev The asset must not be paused
    function unwrap(address _asset, address _to, uint256 _amount) external onlyUnpaused(_asset) {
        collateralToken.safeTransferFrom(msg.sender, collateralToken, _amount);
        CollateralToken(collateralToken).unwrap(_asset, _to, _amount, "");
    }

    function unwrapCallback(address, address, uint256, bytes calldata) external { }
}
