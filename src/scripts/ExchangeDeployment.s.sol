// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script } from "lib/forge-std/src/Script.sol";
import { CTFExchange } from "src/exchange/CTFExchange.sol";
import { ExchangeInitParams } from "src/exchange/libraries/Structs.sol";

/// @title ExchangeDeployment
/// @notice Script to deploy the CTF Exchange
/// @author Polymarket
contract ExchangeDeployment is Script {
    /// @notice Deploys the Exchange contract
    /// @param admin                - The admin for the Exchange
    /// @param collateral           - The collateral token address
    /// @param ctf                  - The CTF address
    /// @param proxyFactory         - The Polymarket proxy factory address
    /// @param safeFactory          - The Polymarket Gnosis Safe factory address
    /// @param feeReceiver          - The address which will receive fees
    function deployExchange(
        address admin,
        address collateral,
        address ctf,
        address proxyFactory,
        address safeFactory,
        address feeReceiver
    ) public returns (address exchange) {
        vm.startBroadcast();

        ExchangeInitParams memory p = ExchangeInitParams({
            collateral: collateral,
            ctf: ctf,
            outcomeTokenFactory: ctf,
            proxyFactory: proxyFactory,
            safeFactory: safeFactory,
            feeReceiver: feeReceiver
        });

        CTFExchange exch = new CTFExchange(p);

        // Grant Auth privileges to the Admin address
        exch.addAdmin(admin);
        exch.addOperator(admin);

        // Revoke the deployer's authorization
        exch.renounceAdminRole();
        exch.renounceOperatorRole();

        exchange = address(exch);
    }

    /// @notice Deploys the Exchange contract
    /// @param admin                - The admin for the Exchange
    /// @param collateral           - The collateral token address
    /// @param ctf                  - The CTF address
    /// @param negRiskAdapter       - The Neg Risk Adapter address
    /// @param proxyFactory         - The Polymarket proxy factory address
    /// @param safeFactory          - The Polymarket Gnosis Safe factory address
    /// @param feeReceiver          - The address which will receive fees
    function deployNrExchange(
        address admin,
        address collateral,
        address ctf,
        address negRiskAdapter,
        address proxyFactory,
        address safeFactory,
        address feeReceiver
    ) public returns (address exchange) {
        vm.startBroadcast();

        ExchangeInitParams memory p = ExchangeInitParams({
            collateral: collateral,
            ctf: ctf,
            outcomeTokenFactory: negRiskAdapter,
            proxyFactory: proxyFactory,
            safeFactory: safeFactory,
            feeReceiver: feeReceiver
        });

        CTFExchange exch = new CTFExchange(p);

        // Grant Auth privileges to the Admin address
        exch.addAdmin(admin);
        exch.addOperator(admin);

        // Revoke the deployer's authorization
        exch.renounceAdminRole();
        exch.renounceOperatorRole();

        exchange = address(exch);
    }
}
