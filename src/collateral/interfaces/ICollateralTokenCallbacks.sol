// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

/// @title ICollateralTokenCallbacks
/// @author Polymarket
/// @notice Callback interface that receivers must implement to participate in CollateralToken
///         wrap/unwrap flows.
/// @dev The CollateralToken invokes these callbacks during wrap and unwrap operations when a
///      non-zero callback receiver is specified.
interface ICollateralTokenCallbacks {
    /// @notice Called by the CollateralToken during a wrap operation before the underlying asset is
    ///         transferred to the vault.
    /// @dev Implementations should transfer the required underlying asset into the CollateralToken
    ///      within this callback.
    /// @param _asset The address of the underlying asset being wrapped
    /// @param _to The address that received the minted collateral tokens
    /// @param _amount The amount of the underlying asset being wrapped
    /// @param _data Arbitrary data forwarded from the original wrap call
    function wrapCallback(address _asset, address _to, uint256 _amount, bytes calldata _data) external;

    /// @notice Called by the CollateralToken during an unwrap operation before collateral tokens
    ///         are burned.
    /// @dev Implementations should transfer the required collateral tokens into the
    ///      CollateralToken within this callback.
    /// @param _asset The address of the underlying asset being unwrapped
    /// @param _to The address that received the unwrapped underlying asset
    /// @param _amount The amount of collateral tokens being burned
    /// @param _data Arbitrary data forwarded from the original unwrap call
    function unwrapCallback(address _asset, address _to, uint256 _amount, bytes calldata _data) external;
}
