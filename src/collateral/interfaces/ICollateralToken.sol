// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface ICollateralToken {
    function wrap(address _asset, address _to, uint256 _amount, bytes calldata _data) external;
    function unwrap(address _asset, address _to, uint256 _amount, bytes calldata _data) external;
}
