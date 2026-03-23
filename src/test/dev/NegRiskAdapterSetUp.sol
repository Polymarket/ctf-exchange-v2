// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { vm } from "@ctf-exchange-v2/src/test/dev/util/vm.sol";
import { Deployer } from "@ctf-exchange-v2/src/test/dev/util/Deployer.sol";
import { IConditionalTokens } from "@ctf-exchange-v2/src/adapters/interfaces/IConditionalTokens.sol";
import { INegRiskAdapter } from "@ctf-exchange-v2/src/adapters/interfaces/INegRiskAdapter.sol";

library NegRiskAdapterSetUp {
    function deploy(address _admin, address _usdce) public returns (INegRiskAdapter, IConditionalTokens, address) {
        address vault = vm.createWallet("vault").addr;

        IConditionalTokens conditionalTokens = IConditionalTokens(Deployer.deployConditionalTokens());

        INegRiskAdapter negRiskAdapter =
            INegRiskAdapter(Deployer.deployNegRiskAdapter(address(conditionalTokens), _usdce, vault));
        negRiskAdapter.addAdmin(_admin);
        negRiskAdapter.renounceAdmin();

        address wrappedCollateralToken = negRiskAdapter.wcol();

        return (negRiskAdapter, conditionalTokens, wrappedCollateralToken);
    }
}
