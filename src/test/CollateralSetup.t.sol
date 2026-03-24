// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { ERC20 } from "@solady/src/tokens/ERC20.sol";

import { TestHelper } from "@ctf-exchange-v2/src/test/dev/TestHelper.sol";
import { Collateral, CollateralSetup } from "@ctf-exchange-v2/src/test/dev/CollateralSetup.sol";

contract CollateralSetUp_Test is TestHelper {
    address admin = alice;

    Collateral collateral;

    function setUp() public {
        collateral = CollateralSetup._deploy(admin);
    }

    function test_setup() public view {
        assertEq(collateral.token.name(), "PolyMarketCollateralToken");
        assertEq(collateral.token.symbol(), "PMCT");
        assertEq(collateral.token.decimals(), 6);

        assertEq(ERC20(collateral.token.USDC()).name(), "USDC");
        assertEq(ERC20(collateral.token.USDC()).symbol(), "USDC");
        assertEq(ERC20(collateral.token.USDC()).decimals(), 6);

        assertEq(ERC20(collateral.token.USDCE()).name(), "USDCe");
        assertEq(ERC20(collateral.token.USDCE()).symbol(), "USDCe");
        assertEq(ERC20(collateral.token.USDCE()).decimals(), 6);
    }
}
