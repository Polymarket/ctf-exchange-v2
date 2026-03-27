// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

/// @title ICollateralToken
/// @author Polymarket
/// @notice Interface for the Polymarket collateral token (ERC-20) that supports minting, burning,
/// and wrapping/unwrapping underlying assets
interface ICollateralToken {
    /// @notice Mints collateral tokens to a recipient
    /// @param _to The address to receive the minted tokens
    /// @param _amount The amount of tokens to mint
    function mint(address _to, uint256 _amount) external;

    /// @notice Burns collateral tokens from the caller
    /// @param _amount The amount of tokens to burn
    function burn(uint256 _amount) external;

    /// @notice Wraps a supported underlying asset into collateral tokens
    /// @dev The underlying asset must be transferred into the contract before this call or during
    ///      the callback.
    /// @param _asset The address of the underlying asset to wrap
    /// @param _to The address to receive the minted collateral tokens
    /// @param _amount The amount of the underlying asset to wrap
    /// @param _callbackReceiver The address to receive a wrap callback, or address(0) to skip
    /// @param _data Arbitrary data forwarded to the callback receiver
    function wrap(address _asset, address _to, uint256 _amount, address _callbackReceiver, bytes calldata _data)
        external;

    /// @notice Unwraps collateral tokens back into a supported underlying asset
    /// @dev Collateral tokens must be transferred into the contract before this call or during the
    ///      callback.
    /// @param _asset The address of the underlying asset to receive
    /// @param _to The address to receive the unwrapped underlying asset
    /// @param _amount The amount of collateral tokens to unwrap
    /// @param _callbackReceiver The address to receive an unwrap callback, or address(0) to skip
    /// @param _data Arbitrary data forwarded to the callback receiver
    function unwrap(address _asset, address _to, uint256 _amount, address _callbackReceiver, bytes calldata _data)
        external;
}
