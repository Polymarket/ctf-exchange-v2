// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { vm } from "./vm.sol";

library Deployer {
    function _deployCode(string memory _what) internal returns (address addr) {
        return _deployCode(_what, "");
    }

    function _deployCode(string memory _what, bytes memory _args) internal returns (address addr) {
        bytes memory bytecode = abi.encodePacked(vm.getCode(_what), _args);
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
    }

    function deployConditionalTokens() internal returns (address) {
        address deployment = _deployCode("artifacts/ConditionalTokens.json");
        vm.label(deployment, "ConditionalTokens");
        return deployment;
    }

    function deployNegRiskAdapter(address _ctf, address _collateral, address _vault) internal returns (address) {
        bytes memory args = abi.encode(_ctf, _collateral, _vault);
        address deployment = _deployCode("artifacts/NegRiskAdapter.json", args);
        vm.label(deployment, "NegRiskAdapter");
        return deployment;
    }
}
