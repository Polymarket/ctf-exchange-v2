// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Env } from "@lattice-std/Lattice.sol";

import { OPERATOR_COUNT } from "../ExecutorOperators.sol";
import { AMOY_CHAIN_ID, BATCHER } from "../OperatorsRelease.sol";
import { OperatorsTestBase } from "./OperatorsTestBase.sol";

/// @notice Before the deploy: the change is still needed, the list is 400 distinct EOAs, and the authority the batcher
///         will answer to administers both venues.
contract PreChange is OperatorsTestBase {
    function test_releaseIsNeeded() public view {
        assertEq(Env.chainId(), AMOY_CHAIN_ID, "the book is not Amoy's");
        assertEq(operators.length, OPERATOR_COUNT, "the list is not 400 executors");
        for (uint256 i; i < operators.length; ++i) {
            assertTrue(operators[i] != address(0), "an executor is the zero address");
            assertEq(operators[i].code.length, 0, "an executor is a contract");
            assertFalse(ctfExchange.isOperator(operators[i]), "an executor already operates the CTF exchange");
            assertFalse(
                negRiskCtfExchange.isOperator(operators[i]), "an executor already operates the NegRisk exchange"
            );
            for (uint256 j = i + 1; j < operators.length; ++j) {
                assertTrue(operators[i] != operators[j], "an executor is listed twice");
            }
        }
        assertEq(authority.code.length, 0, "the authority is not an EOA");
        assertFalse(Env.has(BATCHER), "the book already holds a batcher");
        assertGovernanceIntact();
    }
}
