// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { TestHelper } from "src/test/dev/TestHelper.sol";

import { CollateralErrors } from "src/collateral/abstract/CollateralErrors.sol";
import { Collateral, CollateralSetup, USDCe } from "src/test/dev/CollateralSetup.sol";

contract CollateralOfframpTest is TestHelper {
    error Unauthorized();

    address owner = alice;

    Collateral collateral;
    USDCe usdce;

    function setUp() public {
        collateral = CollateralSetup._deploy(owner);
        usdce = collateral.usdce;
    }

    function test_CollateralOfframp_unwrapUSDCe() public {
        uint256 amount = 100_000_000;
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.onramp), amount);
        collateral.onramp.wrap(alice, amount);

        collateral.token.approve(address(collateral.offramp), amount);
        collateral.offramp.unwrap(alice, amount);
        vm.stopPrank();

        assertEq(usdce.balanceOf(alice), amount);
        assertEq(usdce.balanceOf(collateral.vault), 0);
        assertEq(collateral.token.balanceOf(alice), 0);
    }

    function test_revert_CollateralOfframp_unwrapUSDCe_paused() public {
        uint256 amount = 100_000_000;
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.onramp), amount);
        collateral.onramp.wrap(alice, amount);
        vm.stopPrank();

        vm.prank(owner);
        collateral.offramp.pause(address(usdce));

        vm.startPrank(alice);
        collateral.token.approve(address(collateral.offramp), amount);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        collateral.offramp.unwrap(alice, amount);
        vm.stopPrank();
    }

    function test_Pausable_unpause() public {
        uint256 amount = 100_000_000;
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.onramp), amount);
        collateral.onramp.wrap(alice, amount);
        vm.stopPrank();

        vm.prank(owner);
        collateral.offramp.pause(address(usdce));

        vm.startPrank(alice);
        collateral.token.approve(address(collateral.offramp), amount);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        collateral.offramp.unwrap(alice, amount);
        vm.stopPrank();

        vm.prank(owner);
        collateral.offramp.unpause(address(usdce));

        vm.prank(alice);
        collateral.offramp.unwrap(alice, amount);

        assertEq(usdce.balanceOf(alice), amount);
        assertEq(collateral.token.balanceOf(alice), 0);
    }

    function test_revert_Pausable_pause_unauthorized() public {
        vm.prank(brian);
        vm.expectRevert(Unauthorized.selector);
        collateral.offramp.pause(address(usdce));
    }
}
