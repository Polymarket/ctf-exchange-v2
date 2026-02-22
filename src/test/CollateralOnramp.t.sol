// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { TestHelper } from "src/test/dev/TestHelper.sol";

import { CollateralErrors } from "src/collateral/abstract/CollateralErrors.sol";
import { Collateral, CollateralSetup, USDC, USDCe } from "src/test/dev/CollateralSetup.sol";

contract CollateralOnrampTest is TestHelper {
    error Unauthorized();

    address owner = alice;

    Collateral collateral;
    USDCe usdce;

    function setUp() public {
        collateral = CollateralSetup._deploy(owner);
        usdce = collateral.usdce;
    }

    function test_CollateralOnramp_wrapUSDCe() public {
        uint256 amount = 100_000_000;
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.onramp), amount);
        collateral.onramp.wrap(alice, amount);
        vm.stopPrank();

        assertEq(usdce.balanceOf(alice), 0);
        assertEq(usdce.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(alice), amount);
    }

    function test_revert_CollateralOnramp_wrapUSDCe_paused() public {
        vm.prank(owner);
        collateral.onramp.pause(address(usdce));

        uint256 amount = 100_000_000;
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.onramp), amount);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        collateral.onramp.wrap(alice, amount);
        vm.stopPrank();
    }

    function test_Pausable_unpause() public {
        vm.prank(owner);
        collateral.onramp.pause(address(usdce));

        uint256 amount = 100_000_000;
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.onramp), amount);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        collateral.onramp.wrap(alice, amount);
        vm.stopPrank();

        vm.prank(owner);
        collateral.onramp.unpause(address(usdce));

        vm.startPrank(alice);
        collateral.onramp.wrap(alice, amount);
        vm.stopPrank();

        assertEq(usdce.balanceOf(alice), 0);
        assertEq(usdce.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(alice), amount);
    }

    function test_revert_Pausable_pause_unauthorized() public {
        vm.prank(brian);
        vm.expectRevert(Unauthorized.selector);
        collateral.onramp.pause(address(usdce));
    }
}
