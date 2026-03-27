// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.15;

/// @title ERC1155TokenReceiver
/// @author Polymarket
/// @notice Default ERC1155 token receiver that accepts all transfers.
abstract contract ERC1155TokenReceiver {
    /// @notice Handles receipt of a single ERC1155 token.
    /// @return The function selector for acceptance.
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /// @notice Handles receipt of a batch of ERC1155 tokens.
    /// @return The function selector for acceptance.
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
