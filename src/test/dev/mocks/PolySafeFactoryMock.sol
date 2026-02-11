// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// @notice Mock PolySafeFactory for testing
contract PolySafeFactoryMock {
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function masterCopy() external view returns (address) {
        return implementation;
    }
}
