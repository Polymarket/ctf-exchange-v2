// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

import { GrantNegRiskCtfExchangeOperatorsPlan } from "./OperatorsRelease.sol";

/// @notice Lattice plan, `direct` route: the batcher authorizes the executors on the NegRisk exchange and drops its
/// admin role.
contract GrantNegRiskCtfExchangeOperators is GrantNegRiskCtfExchangeOperatorsPlan { }
