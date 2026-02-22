// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { TestHelper } from "src/test/dev/TestHelper.sol";

import { CollateralErrors } from "src/collateral/abstract/CollateralErrors.sol";
import { Collateral, CollateralSetup, USDC, USDCe } from "src/test/dev/CollateralSetup.sol";

contract PermissionedRampTest is TestHelper {
    error Unauthorized();

    address owner = alice;

    Collateral collateral;
    USDC usdc;
    USDCe usdce;

    function setUp() public {
        collateral = CollateralSetup._deploy(owner);
        usdc = collateral.usdc;
        usdce = collateral.usdce;

        // Grant alice the caller role (ROLE_1)
        vm.prank(owner);
        collateral.permissionedRamp.addCaller(alice);
    }

    // --- wrap ---

    function test_PermissionedRamp_wrapUSDC() public {
        uint256 amount = 100_000_000;
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdc), alice, amount);
        vm.stopPrank();

        assertEq(usdc.balanceOf(alice), 0);
        assertEq(usdc.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(alice), amount);
    }

    function test_PermissionedRamp_wrapUSDCe() public {
        uint256 amount = 100_000_000;
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdce), alice, amount);
        vm.stopPrank();

        assertEq(usdce.balanceOf(alice), 0);
        assertEq(usdce.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(alice), amount);
    }

    // --- unwrap ---

    function test_PermissionedRamp_unwrapUSDC() public {
        uint256 amount = 100_000_000;
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdc), alice, amount);

        collateral.token.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.unwrap(address(usdc), alice, amount);
        vm.stopPrank();

        assertEq(usdc.balanceOf(alice), amount);
        assertEq(usdc.balanceOf(collateral.vault), 0);
        assertEq(collateral.token.balanceOf(alice), 0);
    }

    function test_PermissionedRamp_unwrapUSDCe() public {
        uint256 amount = 100_000_000;
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdce), alice, amount);

        collateral.token.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.unwrap(address(usdce), alice, amount);
        vm.stopPrank();

        assertEq(usdce.balanceOf(alice), amount);
        assertEq(usdce.balanceOf(collateral.vault), 0);
        assertEq(collateral.token.balanceOf(alice), 0);
    }

    // --- access control ---

    function test_revert_PermissionedRamp_wrap_unauthorized() public {
        uint256 amount = 100_000_000;
        usdc.mint(brian, amount);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(Unauthorized.selector);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount);
        vm.stopPrank();
    }

    function test_revert_PermissionedRamp_unwrap_unauthorized() public {
        vm.prank(brian);
        vm.expectRevert(Unauthorized.selector);
        collateral.permissionedRamp.unwrap(address(usdc), brian, 100);
    }

    // --- pause ---

    function test_revert_PermissionedRamp_wrap_paused() public {
        vm.prank(owner);
        collateral.permissionedRamp.pause(address(usdc));

        uint256 amount = 100_000_000;
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        collateral.permissionedRamp.wrap(address(usdc), alice, amount);
        vm.stopPrank();
    }

    function test_revert_PermissionedRamp_unwrap_paused() public {
        uint256 amount = 100_000_000;
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdc), alice, amount);
        vm.stopPrank();

        vm.prank(owner);
        collateral.permissionedRamp.pause(address(usdc));

        vm.startPrank(alice);
        collateral.token.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        collateral.permissionedRamp.unwrap(address(usdc), alice, amount);
        vm.stopPrank();
    }

    // --- admin ---

    function test_PermissionedRamp_addCaller() public {
        vm.prank(owner);
        collateral.permissionedRamp.addCaller(brian);

        uint256 amount = 100_000_000;
        usdc.mint(brian, amount);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount);
        vm.stopPrank();

        assertEq(collateral.token.balanceOf(brian), amount);
    }

    function test_PermissionedRamp_removeCaller() public {
        vm.prank(owner);
        collateral.permissionedRamp.removeCaller(alice);

        uint256 amount = 100_000_000;
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(Unauthorized.selector);
        collateral.permissionedRamp.wrap(address(usdc), alice, amount);
        vm.stopPrank();
    }
}
