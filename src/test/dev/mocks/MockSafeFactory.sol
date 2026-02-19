// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// @notice Mock implementation for safe wallets (supports ERC1155 receiver)
contract MockSafeImplementation {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return 0xbc197c81;
    }
}

/// @notice Mock safe factory that implements masterCopy() and deploySafe()
contract MockSafeFactory {
    address public immutable impl;

    bytes private constant proxyCreationCode =
        hex"608060405234801561001057600080fd5b5060405161017138038061017183398101604081905261002f916100b9565b6001600160a01b0381166100945760405162461bcd60e51b815260206004820152602260248201527f496e76616c69642073696e676c65746f6e20616464726573732070726f766964604482015261195960f21b606482015260840160405180910390fd5b600080546001600160a01b0319166001600160a01b03929092169190911790556100e7565b6000602082840312156100ca578081fd5b81516001600160a01b03811681146100e0578182fd5b9392505050565b607c806100f56000396000f3fe6080604052600080546001600160a01b0316813563530ca43760e11b1415602857808252602082f35b3682833781823684845af490503d82833e806041573d82fd5b503d81f3fea264697066735822122015938e3bf2c49f5df5c1b7f9569fa85cc5d6f3074bb258a2dc0c7e299bc9e33664736f6c63430008040033";

    constructor() {
        impl = address(new MockSafeImplementation());
    }

    function masterCopy() external view returns (address) {
        return impl;
    }

    function deploySafe(address signer) external returns (address safe) {
        bytes memory creationCode = abi.encodePacked(proxyCreationCode, abi.encode(impl));
        bytes32 salt = keccak256(abi.encode(signer));
        assembly {
            safe := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        require(safe != address(0), "deployment failed");
    }
}
