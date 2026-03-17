// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { vm } from "src/test/dev/util/vm.sol";
import { Deployer } from "src/test/dev/util/Deployer.sol";
import { IConditionalTokens } from "src/adapters/interfaces/IConditionalTokens.sol";
import { INegRiskAdapter } from "src/adapters/interfaces/INegRiskAdapter.sol";

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
