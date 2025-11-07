// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script } from "lib/forge-std/src/Script.sol";
import { CTFExchange } from "src/exchange/CTFExchange.sol";

/// @title ExchangeDeployment
/// @notice Script to deploy the CTF Exchange
/// @author Polymarket
contract ExchangeDeployment is Script {
    /// @notice Deploys the Exchange contract
    /// @param admin        - The admin for the Exchange
    /// @param collateral   - The collateral token address
    /// @param ctf          - The CTF address
    /// @param proxyFactory - The Polymarket proxy factory address
    /// @param safeFactory  - The Polymarket Gnosis Safe factory address
    function deployExchange(address admin, address collateral, address ctf, address proxyFactory, address safeFactory)
        public
        returns (address exchange)
    {
        vm.startBroadcast();

        CTFExchange exch = new CTFExchange(collateral, ctf, proxyFactory, safeFactory);

        // Grant Auth privileges to the Admin address
        exch.addAdmin(admin);
        exch.addOperator(admin);

        // Revoke the deployer's authorization
        exch.renounceAdminRole();
        exch.renounceOperatorRole();

        exchange = address(exch);
    }
}
