// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// @notice Mock PolyProxyFactory for testing
contract PolyProxyFactoryMock {
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function getImplementation() external view returns (address) {
        return implementation;
    }

    function setImplementation(address _implementation) external {
        implementation = _implementation;
    }
}
