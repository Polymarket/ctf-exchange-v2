// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { IAuth } from "@ctf-exchange-v2/src/exchange/interfaces/IAuth.sol";

import {
    AddCtfExchangeBatcherAdminPlan,
    AddNegRiskCtfExchangeBatcherAdminPlan,
    GrantCtfExchangeOperatorsPlan,
    GrantNegRiskCtfExchangeOperatorsPlan
} from "../OperatorsRelease.sol";
import { OperatorsTestBase } from "./OperatorsTestBase.sol";

/// @notice After the last grant: every executor operates both venues and administers neither, the batcher administers
///         neither, no plan builds again, and an executor passes each venue's operator gate where a stranger does not.
contract PostChange is OperatorsTestBase {
    function test_everyExecutorIsAuthorized() public {
        assertEveryExecutorAuthorized(ctfExchange);
        assertEveryExecutorAuthorized(negRiskCtfExchange);
        assertGovernanceIntact();
        assertEq(new AddCtfExchangeBatcherAdminPlan().build().length, 0, "the CTF admin grant builds again");
        assertEq(new GrantCtfExchangeOperatorsPlan().build().length, 0, "the CTF grant builds again");
        assertEq(new AddNegRiskCtfExchangeBatcherAdminPlan().build().length, 0, "the NegRisk admin grant builds again");
        assertEq(new GrantNegRiskCtfExchangeOperatorsPlan().build().length, 0, "the NegRisk grant builds again");
    }

    function test_executorsPassTheOperatorGate() public {
        assertOperatorGate(ctfExchange);
        assertOperatorGate(negRiskCtfExchange);
    }

    /// @dev `invalidatePreapprovedOrder` is operator-gated and touches nothing but one flag on this fork: the first and
    ///      the last executor pass the gate, and a stranger is refused.
    function assertOperatorGate(IAuth venue) internal {
        bytes memory call = abi.encodeWithSignature("invalidatePreapprovedOrder(bytes32)", keccak256("lattice"));
        (bool ok,) = tryCallAs(operators[0], address(venue), call);
        assertTrue(ok, "the first executor is refused by the operator gate");
        (ok,) = tryCallAs(operators[operators.length - 1], address(venue), call);
        assertTrue(ok, "the last executor is refused by the operator gate");
        (ok,) = tryCallAs(address(0xbeef), address(venue), call);
        assertFalse(ok, "a stranger passes the operator gate");
    }
}
