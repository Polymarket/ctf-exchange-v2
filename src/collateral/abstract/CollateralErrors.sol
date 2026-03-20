// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

abstract contract CollateralErrors {
    error OnlyUnpaused();
    error InvalidAsset();
    error InvalidSignature();
    error ExpiredDeadline();
    error InvalidNonce();
}
