// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

import { Script } from "@forge-std/src/Script.sol";
import { Deployment, Env } from "@lattice-std/Lattice.sol";

import { ExecutorOperatorBatcher } from "./ExecutorOperatorBatcher.sol";
import { BATCHER, CTF_EXCHANGE, NEG_RISK_CTF_EXCHANGE, requireAmoy } from "./OperatorsRelease.sol";

/// @notice Lattice deploy step: the ExecutorOperatorBatcher, CREATE2 through forge's default deployer, owned by the
///         book's authority (the operating key) and bound to the book's two legacy venues.
/// @dev A target that already has code is reported, not redeployed (the step runs with `skipIfDeployed`).
contract DeployExecutorOperatorBatcher is Script {
    /// @dev The batcher's CREATE2 salt.
    bytes32 public constant BATCHER_SALT = keccak256("ctf-exchange-v2 amoy-executor-operators: batcher");

    function deploy() public returns (Deployment[] memory out) {
        requireAmoy();
        address target = predicted();
        if (target.code.length == 0) {
            address owner = Env.authority();
            address ctfExchange = Env.addr(CTF_EXCHANGE);
            address negRiskCtfExchange = Env.addr(NEG_RISK_CTF_EXCHANGE);
            vm.startBroadcast();
            ExecutorOperatorBatcher deployed =
                new ExecutorOperatorBatcher{ salt: BATCHER_SALT }(owner, ctfExchange, negRiskCtfExchange);
            vm.stopBroadcast();
            require(address(deployed) == target, "batcher: deployed off its prediction");
        }
        out = new Deployment[](1);
        out[0] = Deployment(BATCHER, target);
    }

    /// @dev The batcher's init code, every constructor input from the book.
    function initCode() public view returns (bytes memory) {
        return abi.encodePacked(
            type(ExecutorOperatorBatcher).creationCode,
            abi.encode(Env.authority(), Env.addr(CTF_EXCHANGE), Env.addr(NEG_RISK_CTF_EXCHANGE))
        );
    }

    /// @dev Where the deploy lands.
    function predicted() public view returns (address) {
        return vm.computeCreate2Address(BATCHER_SALT, keccak256(initCode()));
    }
}
