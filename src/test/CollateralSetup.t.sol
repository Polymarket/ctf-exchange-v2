// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC20 } from "lib/solady/src/tokens/ERC20.sol";

import { TestHelper } from "src/test/dev/TestHelper.sol";
import { Collateral, CollateralSetup } from "src/test/dev/CollateralSetup.sol";

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

        assertEq(ERC20(collateral.token.usdc()).name(), "USDC");
        assertEq(ERC20(collateral.token.usdc()).symbol(), "USDC");
        assertEq(ERC20(collateral.token.usdc()).decimals(), 6);

        assertEq(ERC20(collateral.token.usdce()).name(), "USDCe");
        assertEq(ERC20(collateral.token.usdce()).symbol(), "USDCe");
        assertEq(ERC20(collateral.token.usdce()).decimals(), 6);
    }
}
