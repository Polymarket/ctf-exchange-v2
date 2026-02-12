// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { LibClone } from "lib/solady/src/utils/LibClone.sol";

import { vm } from "src/test/dev/util/vm.sol";
import { USDC } from "src/test/dev/mocks/USDC.sol";
import { USDCe } from "src/test/dev/mocks/USDCe.sol";

import { CollateralVault } from "src/test/dev/mocks/CollateralVault.sol";
import { CollateralToken } from "src/collateral/CollateralToken.sol";
import { CollateralOnramp } from "src/collateral/CollateralOnramp.sol";
import { CollateralOfframp } from "src/collateral/CollateralOfframp.sol";

struct Collateral {
    CollateralToken token;
    CollateralOnramp onramp;
    CollateralOfframp offramp;
    USDC usdc;
    USDCe usdce;
    address vault;
}

library CollateralSetup {
    uint256 internal constant ADMIN_ROLE = 1 << 0;
    uint256 internal constant COLLATERAL_GATEKEEPER_ROLE = 1 << 1;

    function _deploy(address _owner) internal returns (Collateral memory) {
        Collateral memory collateral;

        collateral.usdc = new USDC();
        collateral.usdce = new USDCe();

        collateral.vault = address(new CollateralVault(_owner));

        address collateralImplementation = address(
            new CollateralToken(address(collateral.usdc), address(collateral.usdce), address(collateral.vault))
        );

        address collateralProxy = LibClone.deployERC1967(collateralImplementation);

        vm.label(collateralImplementation, "CollateralTokenImplementation");
        vm.label(collateralProxy, "CollateralToken");

        collateral.token = CollateralToken(collateralProxy);
        collateral.token.initialize(_owner);

        collateral.onramp = new CollateralOnramp(_owner, address(collateral.token));
        collateral.offramp = new CollateralOfframp(_owner, address(collateral.token));

        vm.startPrank(_owner);
        collateral.token.grantRoles(address(collateral.onramp), COLLATERAL_GATEKEEPER_ROLE);
        collateral.token.grantRoles(address(collateral.offramp), COLLATERAL_GATEKEEPER_ROLE);
        collateral.onramp.grantRoles(_owner, ADMIN_ROLE);
        collateral.offramp.grantRoles(_owner, ADMIN_ROLE);

        CollateralVault(collateral.vault)
            .approve(address(collateral.usdc), address(collateral.token), type(uint256).max);
        CollateralVault(collateral.vault)
            .approve(address(collateral.usdce), address(collateral.token), type(uint256).max);
        vm.stopPrank();

        return collateral;
    }
}
