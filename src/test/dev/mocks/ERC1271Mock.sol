// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ECDSA } from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract ERC1271Mock {
    address public signer;

    bytes4 internal constant MAGIC_VALUE_1271 = 0x1626ba7e;

    constructor(address _signer) {
        signer = _signer;
    }

    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4) {
        return ECDSA.recover(hash, signature) == signer ? MAGIC_VALUE_1271 : bytes4(0);
    }
}
