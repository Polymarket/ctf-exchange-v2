// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { TestHelper } from "src/test/dev/TestHelper.sol";

import { Collateral, CollateralToken, USDC, USDCe, CollateralSetup } from "src/test/dev/CollateralSetup.sol";
import { CollateralErrors } from "src/collateral/abstract/CollateralErrors.sol";
import { ICollateralTokenCallbacks } from "src/collateral/interfaces/ICollateralTokenCallbacks.sol";

contract MockCollateralTokenRouter is ICollateralTokenCallbacks {
    using SafeTransferLib for address;

    address public immutable collateralToken;

    constructor(address _collateralToken) {
        collateralToken = _collateralToken;
    }

    function wrap(address _asset, address _to, uint256 _amount) external {
        bytes memory data = abi.encode(msg.sender);
        CollateralToken(collateralToken).wrap(_asset, _to, _amount, data);
    }

    function unwrap(address _asset, address _to, uint256 _amount) external {
        bytes memory data = abi.encode(msg.sender);
        CollateralToken(collateralToken).unwrap(_asset, _to, _amount, data);
    }

    function wrapCallback(address _asset, address, uint256 _amount, bytes calldata _data) external {
        address from = abi.decode(_data, (address));
        _asset.safeTransferFrom(from, collateralToken, _amount);
    }

    function unwrapCallback(address, address, uint256 _amount, bytes calldata _data) external {
        address from = abi.decode(_data, (address));
        collateralToken.safeTransferFrom(from, collateralToken, _amount);
    }
}

contract CollateralTokenTest is TestHelper {
    error Unauthorized();

    address admin = alice;

    Collateral collateral;
    USDC usdc;
    USDCe usdce;

    MockCollateralTokenRouter router;

    function setUp() public {
        collateral = CollateralSetup._deploy(admin);
        usdc = collateral.usdc;
        usdce = collateral.usdce;

        router = new MockCollateralTokenRouter(address(collateral.token));

        vm.prank(admin);
        collateral.token.grantRoles(address(router), 1 << 1);
    }

    function test_CollateralToken_wrapUSDC() public {
        uint256 amount = 100_000_000;
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(router), amount);
        router.wrap(address(usdc), brian, amount);
        vm.stopPrank();

        assertEq(usdc.balanceOf(alice), 0);
        assertEq(usdc.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(brian), amount);
    }

    function test_CollateralToken_wrapUSDCe() public {
        uint256 amount = 100_000_000;
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(router), amount);
        router.wrap(address(usdce), brian, amount);
        vm.stopPrank();

        assertEq(usdce.balanceOf(alice), 0);
        assertEq(usdce.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(brian), amount);
    }

    function test_CollateralToken_unwrapUSDC() public {
        uint256 amount = 100_000_000;
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(router), amount);
        router.wrap(address(usdc), brian, amount);
        vm.stopPrank();

        vm.startPrank(brian);
        collateral.token.approve(address(router), amount);
        router.unwrap(address(usdc), alice, amount);
        vm.stopPrank();

        assertEq(usdc.balanceOf(alice), amount);
        assertEq(usdc.balanceOf(collateral.vault), 0);
        assertEq(collateral.token.balanceOf(brian), 0);
    }

    function test_CollateralToken_unwrapUSDCe() public {
        uint256 amount = 100_000_000;
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(router), amount);
        router.wrap(address(usdce), brian, amount);
        vm.stopPrank();

        vm.startPrank(brian);
        collateral.token.approve(address(router), amount);
        router.unwrap(address(usdce), alice, amount);
        vm.stopPrank();

        assertEq(usdce.balanceOf(alice), amount);
        assertEq(usdce.balanceOf(collateral.vault), 0);
        assertEq(collateral.token.balanceOf(brian), 0);
    }

    function test_revert_CollateralToken_wrapInvalidAsset(address _invalidAsset) public {
        vm.assume(_invalidAsset != address(usdc) && _invalidAsset != address(usdce));

        uint256 amount = 100_000_000;
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(router), amount);
        vm.expectRevert(CollateralErrors.InvalidAsset.selector);
        router.wrap(_invalidAsset, brian, amount);
    }

    function test_revert_CollateralToken_unwrapInvalidAsset(address _invalidAsset) public {
        vm.assume(_invalidAsset != address(usdc) && _invalidAsset != address(usdce));

        uint256 amount = 100_000_000;
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(router), amount);
        router.wrap(address(usdc), alice, amount);
        collateral.token.approve(address(router), amount);
        vm.expectRevert(CollateralErrors.InvalidAsset.selector);
        router.unwrap(_invalidAsset, brian, amount);
        vm.stopPrank();
    }

    function test_revert_CollateralToken_wrap_unauthorized() public {
        uint256 amount = 100_000_000;

        vm.expectRevert(Unauthorized.selector);
        vm.prank(alice);
        collateral.token.wrap(address(usdc), alice, amount, "");
    }

    function test_revert_CollateralToken_unwrap_unauthorized() public {
        uint256 amount = 100_000_000;

        vm.expectRevert(Unauthorized.selector);
        vm.prank(alice);
        collateral.token.unwrap(address(usdc), alice, amount, "");
    }

    function test_revert_CollateralToken_unwrap_insufficientBalance() public {
        uint256 wrapAmount = 100_000_000;
        uint256 unwrapAmount = 200_000_000;

        usdc.mint(alice, wrapAmount);

        vm.startPrank(alice);
        usdc.approve(address(router), wrapAmount);
        router.wrap(address(usdc), alice, wrapAmount);
        vm.stopPrank();

        vm.startPrank(alice);
        collateral.token.approve(address(router), unwrapAmount);
        vm.expectRevert();
        router.unwrap(address(usdc), alice, unwrapAmount);
        vm.stopPrank();
    }
}
