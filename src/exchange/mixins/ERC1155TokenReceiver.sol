// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract ERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        virtual
        returns (bytes4)
    {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }

    /// @notice ERC-165 interface detection
    /// @param interfaceId - The interface identifier to check
    function supportsInterface(bytes4 interfaceId) external pure virtual returns (bool) {
        return interfaceId == 0x4e2312e0 // ERC1155TokenReceiver
            || interfaceId == 0x01ffc9a7; // ERC165
    }
}
