// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// @notice Mock implementation for proxy wallets (supports ERC1155 receiver)
contract MockProxyImplementation {
    function cloneConstructor(bytes memory) external { }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return 0xbc197c81; // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    }
}

/// @notice Mock proxy factory that implements getImplementation() and deployProxy()
contract MockProxyFactory {
    address public immutable impl;

    constructor() {
        impl = address(new MockProxyImplementation());
    }

    function getImplementation() external view returns (address) {
        return impl;
    }

    /// @dev Called by proxy during deployment initialization
    function cloneConstructor(bytes memory) external { }

    function deployProxy(address signer) external returns (address proxy) {
        bytes memory creationCode = _computeCreationCode(address(this), impl);
        bytes32 salt = keccak256(abi.encodePacked(signer));
        assembly {
            proxy := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        require(proxy != address(0), "deployment failed");
    }

    /// @dev Copy of PolyProxyLib._computeCreationCode for test use
    function _computeCreationCode(address deployer, address target) internal pure returns (bytes memory clone) {
        bytes memory consData = abi.encodeWithSignature("cloneConstructor(bytes)", new bytes(0));
        bytes memory buffer = new bytes(99);
        assembly {
            mstore(add(buffer, 0x20), 0x3d3d606380380380913d393d73bebebebebebebebebebebebebebebebebebebe)
            mstore(add(buffer, 0x2d), mul(deployer, 0x01000000000000000000000000))
            mstore(add(buffer, 0x41), 0x5af4602a57600080fd5b602d8060366000396000f3363d3d373d3d3d363d73be)
            mstore(add(buffer, 0x60), mul(target, 0x01000000000000000000000000))
            mstore(add(buffer, 116), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        }
        clone = abi.encodePacked(buffer, consData);
    }
}
