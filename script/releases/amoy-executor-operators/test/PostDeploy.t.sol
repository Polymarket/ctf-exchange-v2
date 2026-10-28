// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { Call } from "@lattice-std/Lattice.sol";

import { IAuth } from "@ctf-exchange-v2/src/exchange/interfaces/IAuth.sol";

import { ExecutorOperatorBatcher } from "../ExecutorOperatorBatcher.sol";
import {
    AddBatcherAdminPlan,
    AddCtfExchangeBatcherAdminPlan,
    AddNegRiskCtfExchangeBatcherAdminPlan,
    GrantCtfExchangeOperatorsPlan,
    GrantNegRiskCtfExchangeOperatorsPlan,
    GrantOperatorsPlan
} from "../OperatorsRelease.sol";
import { OperatorsTestBase } from "./OperatorsTestBase.sol";

/// @dev The step scripts are these plans (`2-AddCtfExchangeBatcherAdmin.s.sol` is `AddCtfExchangeBatcherAdminPlan`),
///      so the suite builds the same calls through the plans themselves.
abstract contract BatcherTestBase is OperatorsTestBase {
    ExecutorOperatorBatcher internal batcherContract;

    function setUp() public virtual override {
        super.setUp();
        if (!materialized()) return;
        batcherContract = ExecutorOperatorBatcher(batcher());
    }

    /// @dev The venue's two plans applied as the authority, the way `lattice run` sends them on the direct route,
    ///      each checked against the call it must be.
    function rehearse(IAuth venue, AddBatcherAdminPlan addAdmin, GrantOperatorsPlan grant) internal {
        vm.expectRevert(bytes("venue: the batcher is not an admin"));
        grant.build();

        Call[] memory calls = addAdmin.build();
        assertEq(calls.length, 1, "the admin grant is not one call");
        assertEq(calls[0].to, address(venue), "the admin grant targets another contract");
        assertEq(calls[0].value, 0, "the admin grant sends value");
        assertEq(calls[0].data, abi.encodeCall(IAuth.addAdmin, (batcher())), "the admin grant is another call");
        callAsAuthority(calls[0].to, calls[0].data);
        assertTrue(venue.isAdmin(batcher()), "the batcher is not an admin");
        assertEq(addAdmin.build().length, 0, "the admin grant builds again");

        calls = grant.build();
        assertEq(calls.length, 1, "the grant is not one call");
        assertEq(calls[0].to, batcher(), "the grant targets another contract");
        assertEq(calls[0].value, 0, "the grant sends value");
        assertEq(
            calls[0].data,
            abi.encodeCall(ExecutorOperatorBatcher.grantOperators, (address(venue))),
            "the grant is another call"
        );
        callAsAuthority(calls[0].to, calls[0].data);
        assertEveryExecutorAuthorized(venue);
        assertFalse(venue.isAdmin(batcher()), "the batcher is still an admin");
        assertEq(grant.build().length, 0, "the grant builds again");
        assertEq(addAdmin.build().length, 0, "the admin grant builds again after the grant");
    }
}

/// @notice After the deploy: the batcher answers to the operating key alone, is bound to the book's two venues and the
///         list, administers neither venue, and refuses every caller and every venue it was not built for.
contract PostDeploy is BatcherTestBase {
    function test_batcherIsLockedToTheOperatingKey() public view {
        assertGt(batcher().code.length, 0, "the batcher has no code");
        assertEq(batcherContract.owner(), authority, "the batcher answers to another account");
        assertEq(batcherContract.ctfExchange(), address(ctfExchange), "the batcher is bound to another CTF exchange");
        assertEq(
            batcherContract.negRiskCtfExchange(),
            address(negRiskCtfExchange),
            "the batcher is bound to another NegRisk exchange"
        );
        address[] memory listed = batcherContract.operators();
        assertEq(listed.length, operators.length, "the batcher carries another list");
        for (uint256 i; i < listed.length; ++i) {
            assertEq(listed[i], operators[i], "the batcher's list is out of order");
        }
        assertGovernanceIntact();
    }

    function test_batcherRefusesAnyoneButTheOperatingKey() public {
        // Even with the admin role on the venue, a caller other than the owner is refused.
        callAsAuthority(address(ctfExchange), abi.encodeCall(IAuth.addAdmin, (batcher())));
        bytes memory grant = abi.encodeCall(ExecutorOperatorBatcher.grantOperators, (address(ctfExchange)));
        address[3] memory strangers = [address(0xbeef), operators[0], address(ctfExchange)];
        for (uint256 i; i < strangers.length; ++i) {
            (bool ok, bytes memory ret) = tryCallAs(strangers[i], batcher(), grant);
            assertFalse(ok, "a stranger runs the batcher");
            assertEq(ret, abi.encodeWithSelector(ExecutorOperatorBatcher.NotOwner.selector), "another refusal");
        }
        assertFalse(ctfExchange.isOperator(operators[0]), "a refused call authorized an executor");
    }

    function test_batcherRefusesAnotherVenue() public {
        (bool ok, bytes memory ret) =
            tryCallAs(authority, batcher(), abi.encodeCall(ExecutorOperatorBatcher.grantOperators, (address(0xbeef))));
        assertFalse(ok, "the batcher acts on an unknown venue");
        assertEq(ret, abi.encodeWithSelector(ExecutorOperatorBatcher.UnknownVenue.selector), "another refusal");
    }

    function test_batcherRefusesAVenueItDoesNotAdminister() public {
        (bool ok, bytes memory ret) = tryCallAs(
            authority, batcher(), abi.encodeCall(ExecutorOperatorBatcher.grantOperators, (address(ctfExchange)))
        );
        assertFalse(ok, "the batcher runs without the admin role");
        assertEq(ret, abi.encodeWithSelector(ExecutorOperatorBatcher.NotVenueAdmin.selector), "another refusal");
    }
}

/// @notice The release's plans applied on the fork, CTF exchange first and then the NegRisk exchange, as the steps
///         run: every executor authorized on both, the batcher left administering neither.
contract PostDeployRehearsal is BatcherTestBase {
    function test_plansApplied() public {
        rehearse(ctfExchange, new AddCtfExchangeBatcherAdminPlan(), new GrantCtfExchangeOperatorsPlan());
        for (uint256 i; i < operators.length; ++i) {
            assertFalse(negRiskCtfExchange.isOperator(operators[i]), "the CTF grant reached the NegRisk exchange");
        }
        rehearse(
            negRiskCtfExchange, new AddNegRiskCtfExchangeBatcherAdminPlan(), new GrantNegRiskCtfExchangeOperatorsPlan()
        );
        assertGovernanceIntact();
    }
}
