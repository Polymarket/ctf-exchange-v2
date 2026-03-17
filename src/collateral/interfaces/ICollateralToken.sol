// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

interface ICollateralToken {
    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
    function wrap(address _asset, address _to, uint256 _amount, address _callbackReceiver, bytes calldata _data)
        external;
    function unwrap(address _asset, address _to, uint256 _amount, address _callbackReceiver, bytes calldata _data)
        external;
}
