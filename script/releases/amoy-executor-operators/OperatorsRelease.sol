// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

import { Script } from "@forge-std/src/Script.sol";
import { Call, Env } from "@lattice-std/Lattice.sol";

import { IAuth } from "@ctf-exchange-v2/src/exchange/interfaces/IAuth.sol";

import { ExecutorOperatorBatcher } from "./ExecutorOperatorBatcher.sol";

/// @dev The release is Amoy's: the one chain-specific literal it carries, on purpose. It records no version, so this
///      is what refuses a book for any other chain, should another ever reach it.
uint256 constant AMOY_CHAIN_ID = 80002;

/// @dev The book's name for the batcher the deploy step records.
string constant BATCHER = "executorOperatorBatcher";

/// @dev The book's names for the two legacy venues.
string constant CTF_EXCHANGE = "ctfExchangeV2";
string constant NEG_RISK_CTF_EXCHANGE = "negRiskCtfExchangeV2";

/// @dev Every script of the release calls this before it builds or deploys.
function requireAmoy() view {
    require(Env.chainId() == AMOY_CHAIN_ID, "amoy-executor-operators runs on Amoy only");
}

/// @dev The number of executors the venue does not yet authorize.
function missingOn(IAuth venue, address[] memory ops) view returns (uint256 n) {
    for (uint256 i; i < ops.length; ++i) {
        if (!venue.isOperator(ops[i])) ++n;
    }
}

/// @notice What every plan of the release shares: one venue, the batcher, and the checks both plans start from.
abstract contract VenuePlan is Script {
    /// @dev The book's name for the venue the plan acts on.
    function venueName() public pure virtual returns (string memory);

    /// @dev The venue and the batcher, once the venue is administered by the authority and the batcher answers to it.
    function _context() internal view returns (IAuth venue, ExecutorOperatorBatcher batcher) {
        requireAmoy();
        venue = IAuth(Env.addr(venueName()));
        batcher = ExecutorOperatorBatcher(Env.addr(BATCHER));
        require(venue.isAdmin(Env.authority()), "venue: the authority is not an admin");
        require(batcher.owner() == Env.authority(), "batcher: not owned by the authority");
    }
}

/// @notice Lattice plan, `direct` route: make the batcher an admin of the venue, for the grant that follows. Nothing to
///         do once the batcher is an admin, or when the venue already authorizes every executor.
abstract contract AddBatcherAdminPlan is VenuePlan {
    function build() public view returns (Call[] memory calls) {
        (IAuth venue, ExecutorOperatorBatcher batcher) = _context();
        if (venue.isAdmin(address(batcher)) || missingOn(venue, batcher.operators()) == 0) return calls;

        calls = new Call[](1);
        calls[0] = Call(address(venue), 0, abi.encodeCall(IAuth.addAdmin, (address(batcher))));
    }
}

/// @notice Lattice plan, `direct` route: have the batcher authorize every missing executor on the venue and remove its
///         own admin role. Builds nothing once the venue authorizes every executor and the batcher holds no admin role.
abstract contract GrantOperatorsPlan is VenuePlan {
    function build() public view returns (Call[] memory calls) {
        (IAuth venue, ExecutorOperatorBatcher batcher) = _context();
        if (!venue.isAdmin(address(batcher))) {
            require(missingOn(venue, batcher.operators()) == 0, "venue: the batcher is not an admin");
            return calls;
        }

        calls = new Call[](1);
        calls[0] = Call(address(batcher), 0, abi.encodeCall(ExecutorOperatorBatcher.grantOperators, (address(venue))));
    }
}

/// @notice The batcher made an admin of the CTF exchange.
contract AddCtfExchangeBatcherAdminPlan is AddBatcherAdminPlan {
    function venueName() public pure override returns (string memory) {
        return CTF_EXCHANGE;
    }
}

/// @notice The executors authorized on the CTF exchange.
contract GrantCtfExchangeOperatorsPlan is GrantOperatorsPlan {
    function venueName() public pure override returns (string memory) {
        return CTF_EXCHANGE;
    }
}

/// @notice The batcher made an admin of the NegRisk CTF exchange.
contract AddNegRiskCtfExchangeBatcherAdminPlan is AddBatcherAdminPlan {
    function venueName() public pure override returns (string memory) {
        return NEG_RISK_CTF_EXCHANGE;
    }
}

/// @notice The executors authorized on the NegRisk CTF exchange.
contract GrantNegRiskCtfExchangeOperatorsPlan is GrantOperatorsPlan {
    function venueName() public pure override returns (string memory) {
        return NEG_RISK_CTF_EXCHANGE;
    }
}
