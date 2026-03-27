// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

abstract contract IAssets {
    function getCollateral() public virtual returns (address);

    function getCtf() public virtual returns (address);

    function getCtfCollateral() public virtual returns (address);

    function getOutcomeTokenFactory() public virtual returns (address);
}
