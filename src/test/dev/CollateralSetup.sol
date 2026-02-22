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
import { PermissionedRamp } from "src/collateral/PermissionedRamp.sol";

struct Collateral {
    CollateralToken token;
    CollateralOnramp onramp;
    CollateralOfframp offramp;
    PermissionedRamp permissionedRamp;
    USDC usdc;
    USDCe usdce;
    address vault;
}

library CollateralSetup {
    uint256 internal constant ADMIN_ROLE = 1 << 0;
    uint256 internal constant CALLER_ROLE = 1 << 1;

    function _deploy(address _admin) internal returns (Collateral memory) {
        return _deploy(_admin, _admin);
    }

    function _deploy(address _owner, address _admin) internal returns (Collateral memory) {
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
        collateral.token.initialize(_owner, _admin);

        collateral.onramp = new CollateralOnramp(_admin, address(collateral.token), address(collateral.usdce));
        collateral.offramp = new CollateralOfframp(_admin, address(collateral.token), address(collateral.usdce));
        collateral.permissionedRamp = new PermissionedRamp(_admin, address(collateral.token));

        vm.startPrank(_admin);
        collateral.token.addRouter(address(collateral.onramp));
        collateral.token.addRouter(address(collateral.offramp));
        collateral.token.addRouter(address(collateral.permissionedRamp));
        collateral.onramp.grantRoles(_admin, ADMIN_ROLE);
        collateral.offramp.grantRoles(_admin, ADMIN_ROLE);
        collateral.permissionedRamp.grantRoles(_admin, ADMIN_ROLE);
        vm.stopPrank();

        vm.startPrank(_owner);
        CollateralVault(collateral.vault)
            .approve(address(collateral.usdc), address(collateral.token), type(uint256).max);
        CollateralVault(collateral.vault)
            .approve(address(collateral.usdce), address(collateral.token), type(uint256).max);
        vm.stopPrank();

        return collateral;
    }
}
