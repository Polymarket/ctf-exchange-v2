// SPDX-License-Identifier: BUSL-1.1
pragma solidity <0.9.0;

import { ERC20 } from "@solady/src/tokens/ERC20.sol";
import { ERC1155 } from "@solady/src/tokens/ERC1155.sol";

import { IAssets } from "../interfaces/IAssets.sol";
import { IAssetOperations } from "../interfaces/IAssetOperations.sol";
import { IConditionalTokens } from "../interfaces/IConditionalTokens.sol";

import { TransferHelper } from "../libraries/TransferHelper.sol";

import { Assets } from "./Assets.sol";

/// @title Asset Operations
/// @notice Operations on the CTF and Collateral assets
abstract contract AssetOperations is Assets, IAssetOperations {
    bytes32 public constant PARENT_COLLECTION_ID = bytes32(0);

    function _getBalance(uint256 tokenId) internal view override returns (uint256) {
        if (tokenId == 0) return ERC20(getCollateral()).balanceOf(address(this));
        return ERC1155(getCtf()).balanceOf(address(this), tokenId);
    }

    function _transfer(address from, address to, uint256 id, uint256 value) internal override {
        if (id == 0) return _transferCollateral(from, to, value);
        return _transferCTF(from, to, id, value);
    }

    function _transferCollateral(address from, address to, uint256 value) internal {
        address token = getCollateral();
        if (from == address(this)) TransferHelper._transferERC20(token, to, value);
        else TransferHelper._transferFromERC20(token, from, to, value);
    }

    function _transferCTF(address from, address to, uint256 id, uint256 value) internal {
        TransferHelper._transferFromERC1155(getCtf(), from, to, id, value);
    }

    function _mint(bytes32 conditionId, uint256 amount) internal override {
        uint256[] memory partition = _getPartition();
        IConditionalTokens(getOutcomeTokenFactory())
            .splitPosition(getCollateral(), PARENT_COLLECTION_ID, conditionId, partition, amount);
    }

    function _merge(bytes32 conditionId, uint256 amount) internal override {
        uint256[] memory partition = _getPartition();
        IConditionalTokens(getOutcomeTokenFactory())
            .mergePositions(getCollateral(), PARENT_COLLECTION_ID, conditionId, partition, amount);
    }

    /// @dev Returns the binary partition [1, 2] for CTF operations
    function _getPartition() internal pure returns (uint256[] memory partition) {
        assembly ("memory-safe") {
            // Allocate memory for array: 32 bytes for length + 64 bytes for 2 elements
            partition := mload(0x40)
            mstore(partition, 2) // length = 2
            mstore(add(partition, 0x20), 1) // partition[0] = 1
            mstore(add(partition, 0x40), 2) // partition[1] = 2
            mstore(0x40, add(partition, 0x60)) // Update free memory pointer
        }
    }
}
