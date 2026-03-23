// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { ECDSA } from "@solady/src/utils/ECDSA.sol";

contract ToggleableERC1271Mock {
    address public signer;
    bool public disabled;

    bytes4 internal constant MAGIC_VALUE_1271 = 0x1626ba7e;

    constructor(address _signer) {
        signer = _signer;
    }

    function disable() external {
        disabled = true;
    }

    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4) {
        require(!disabled, "disabled");
        return ECDSA.recover(hash, signature) == signer ? MAGIC_VALUE_1271 : bytes4(0);
    }

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
