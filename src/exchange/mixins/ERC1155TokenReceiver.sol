// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract ERC1155TokenReceiver {
    /// @dev Fallback function to handle token callbacks.
    fallback() external payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, calldataload(0))
            // 0xf23a6e61: `onERC1155Received(address,address,uint256,uint256,bytes)`.
            // 0xbc197c81: `onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)`.
            if or(eq(s, 0xf23a6e61), eq(s, 0xbc197c81)) {
                // Assumes `mload(0x40) <= 0xffffffff` to save gas on cleaning lower bytes.
                mstore(0x20, s) // Store `msg.sig`.
                return(0x3c, 0x20) // Return `msg.sig`.
            }

            mstore(0x00, 0x3c10b94e) // `FnSelectorNotRecognized()`.
            revert(0x1c, 0x04)
        }
    }
}
