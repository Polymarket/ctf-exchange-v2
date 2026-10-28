// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

import { IAuth } from "@ctf-exchange-v2/src/exchange/interfaces/IAuth.sol";

import { executorOperators } from "./ExecutorOperators.sol";

/// @title ExecutorOperatorBatcher
/// @notice One-shot helper that authorizes the preprod Amoy CLOB executors as operators of the two legacy venues.
/// @author Polymarket
/// @dev The venues' admin is an EOA, which sends one call per transaction, so 400 `addOperator` calls per venue would
///      be 400 transactions. The EOA instead makes this contract an admin of one venue, then has it add every missing
///      executor and remove its own admin role, in one transaction. It answers to its owner, the operating key, alone:
///      the venues and the executors are fixed at deployment, so even the owner can make it do nothing else.
contract ExecutorOperatorBatcher {
    /// @notice Thrown when the caller is not the owner.
    error NotOwner();

    /// @notice Thrown when the venue is not one of the two the batcher was deployed for.
    error UnknownVenue();

    /// @notice Thrown when the batcher is not an admin of the venue.
    error NotVenueAdmin();

    /// @notice Thrown when a constructor input is the zero address.
    error ZeroAddress();

    /// @notice The operating key: the only account that may call the batcher.
    address public immutable owner;

    /// @notice The CTF exchange (ctfExchangeV2) the batcher may authorize the executors on.
    address public immutable ctfExchange;

    /// @notice The NegRisk CTF exchange (negRiskCtfExchangeV2) the batcher may authorize the executors on.
    address public immutable negRiskCtfExchange;

    /// @param _owner The operating key, the venues' admin.
    /// @param _ctfExchange The CTF exchange.
    /// @param _negRiskCtfExchange The NegRisk CTF exchange.
    constructor(address _owner, address _ctfExchange, address _negRiskCtfExchange) {
        require(_owner != address(0) && _ctfExchange != address(0) && _negRiskCtfExchange != address(0), ZeroAddress());
        owner = _owner;
        ctfExchange = _ctfExchange;
        negRiskCtfExchange = _negRiskCtfExchange;
    }

    /// @notice The executors the batcher authorizes, in list order.
    /// @return The executor addresses.
    function operators() external pure returns (address[] memory) {
        return executorOperators();
    }

    /// @notice Authorizes every executor the venue does not yet authorize, then removes the batcher's admin role.
    /// @dev Only the owner, on one of the two venues, while the batcher is that venue's admin.
    /// @param _venue The venue: the CTF exchange or the NegRisk CTF exchange.
    function grantOperators(address _venue) external {
        require(msg.sender == owner, NotOwner());
        require(_venue == ctfExchange || _venue == negRiskCtfExchange, UnknownVenue());
        require(IAuth(_venue).isAdmin(address(this)), NotVenueAdmin());

        address[] memory ops = executorOperators();
        for (uint256 i; i < ops.length; ++i) {
            if (!IAuth(_venue).isOperator(ops[i])) IAuth(_venue).addOperator(ops[i]);
        }
        IAuth(_venue).removeAdmin(address(this));
    }
}
