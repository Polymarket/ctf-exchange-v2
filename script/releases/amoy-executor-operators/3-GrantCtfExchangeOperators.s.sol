// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

import { GrantCtfExchangeOperatorsPlan } from "./OperatorsRelease.sol";

/// @notice Lattice plan, `direct` route: the batcher authorizes the executors on the CTF exchange and drops its admin
/// role.
contract GrantCtfExchangeOperators is GrantCtfExchangeOperatorsPlan { }
