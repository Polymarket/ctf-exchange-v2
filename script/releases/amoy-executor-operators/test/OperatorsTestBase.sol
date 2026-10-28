// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Test } from "@forge-std/src/Test.sol";
import { Env } from "@lattice-std/Lattice.sol";
import { LatticeTest } from "@lattice-std/LatticeTest.sol";

import { IAuth } from "@ctf-exchange-v2/src/exchange/interfaces/IAuth.sol";

import { executorOperators } from "../ExecutorOperators.sol";
import { BATCHER, CTF_EXCHANGE, NEG_RISK_CTF_EXCHANGE } from "../OperatorsRelease.sol";

/// @notice Shared ground for the release's checks. Every address comes from the book Lattice materializes at
///         .lattice/env.json, so the same suites run on a fork (`lattice test`) and on the chain (`lattice run`).
abstract contract OperatorsTestBase is Test, LatticeTest {
    IAuth internal ctfExchange;
    IAuth internal negRiskCtfExchange;
    address internal authority;
    address[] internal operators;

    function setUp() public virtual {
        // Step hooks: Lattice materializes the book and forks the chain before it runs them. A plain
        // `forge test` over the repository has neither, so the suite skips.
        skipUnlessMaterialized();
        if (!materialized()) return;
        ctfExchange = IAuth(Env.addr(CTF_EXCHANGE));
        negRiskCtfExchange = IAuth(Env.addr(NEG_RISK_CTF_EXCHANGE));
        authority = Env.authority();
        operators = executorOperators();
    }

    /// @dev The batcher the deploy step recorded.
    function batcher() internal view returns (address) {
        return Env.addr(BATCHER);
    }

    /// @dev Governance as it must read before and after: the authority administers both venues and the batcher, when
    ///      the book holds one, administers neither.
    function assertGovernanceIntact() internal view {
        assertTrue(ctfExchange.isAdmin(authority), "the authority is not the CTF exchange's admin");
        assertTrue(negRiskCtfExchange.isAdmin(authority), "the authority is not the NegRisk exchange's admin");
        if (Env.has(BATCHER)) {
            assertFalse(ctfExchange.isAdmin(batcher()), "the batcher administers the CTF exchange");
            assertFalse(negRiskCtfExchange.isAdmin(batcher()), "the batcher administers the NegRisk exchange");
        }
    }

    /// @dev Every executor is an operator of the venue and none is its admin.
    function assertEveryExecutorAuthorized(IAuth venue) internal view {
        for (uint256 i; i < operators.length; ++i) {
            assertTrue(venue.isOperator(operators[i]), "an executor is not an operator");
            assertFalse(venue.isAdmin(operators[i]), "an executor is an admin");
        }
    }
}
