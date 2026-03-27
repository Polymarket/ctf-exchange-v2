// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

/// @title CollateralErrors
/// @author Polymarket
/// @notice Custom errors for the collateral token system.
abstract contract CollateralErrors {
    /// @notice Thrown when an operation is attempted on a paused asset.
    error OnlyUnpaused();
    /// @notice Thrown when the asset is not a supported collateral type (USDC or USDCe).
    error InvalidAsset();
    /// @notice Thrown when the EIP-712 witness signature verification fails.
    error InvalidSignature();
    /// @notice Thrown when the signature deadline has passed.
    error ExpiredDeadline();
    /// @notice Thrown when the nonce does not match the sender's current nonce.
    error InvalidNonce();
}
