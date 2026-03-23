// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { Ownable } from "@solady/src/auth/Ownable.sol";

import { TestHelper } from "@ctf-exchange-v2/src/test/dev/TestHelper.sol";

import {
    Collateral,
    CollateralToken,
    USDC,
    USDCe,
    CollateralSetup
} from "@ctf-exchange-v2/src/test/dev/CollateralSetup.sol";
import { CollateralErrors } from "@ctf-exchange-v2/src/collateral/abstract/CollateralErrors.sol";
import { CollateralTokenEvents } from "@ctf-exchange-v2/src/collateral/CollateralToken.sol";
import { ICollateralTokenCallbacks } from "@ctf-exchange-v2/src/collateral/interfaces/ICollateralTokenCallbacks.sol";

contract MockCollateralTokenRouter is ICollateralTokenCallbacks {
    using SafeTransferLib for address;

    address public immutable collateralToken;

    constructor(address _collateralToken) {
        collateralToken = _collateralToken;
    }

    function wrap(address _asset, address _to, uint256 _amount) external {
        bytes memory data = abi.encode(msg.sender);
        CollateralToken(collateralToken).wrap(_asset, _to, _amount, address(this), data);
    }

    function unwrap(address _asset, address _to, uint256 _amount) external {
        bytes memory data = abi.encode(msg.sender);
        CollateralToken(collateralToken).unwrap(_asset, _to, _amount, address(this), data);
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

contract CollateralTokenTest is TestHelper, CollateralTokenEvents {
    address owner = alice;

    Collateral collateral;
    USDC usdc;
    USDCe usdce;

    MockCollateralTokenRouter router;
    address minter;

    uint256 amount = 100_000_000;

    function setUp() public {
        collateral = CollateralSetup._deploy(owner);
        usdc = collateral.usdc;
        usdce = collateral.usdce;

        minter = vm.createWallet("minter").addr;
        router = new MockCollateralTokenRouter(address(collateral.token));

        vm.startPrank(owner);
        collateral.token.addWrapper(address(router));
        collateral.token.addMinter(minter);
        vm.stopPrank();
    }

    /*--------------------------------------------------------------
                            INITIALIZE
    --------------------------------------------------------------*/

    function test_CollateralToken_initialize() public view {
        assertEq(collateral.token.owner(), owner);
    }

    function test_revert_CollateralToken_initialize_alreadyInitialized() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        collateral.token.initialize(alice);
    }

    /*--------------------------------------------------------------
                              VIEW
    --------------------------------------------------------------*/

    function test_CollateralToken_name() public view {
        assertEq(collateral.token.name(), "PolyMarketCollateralToken");
    }

    function test_CollateralToken_symbol() public view {
        assertEq(collateral.token.symbol(), "PMCT");
    }

    function test_CollateralToken_decimals() public view {
        assertEq(collateral.token.decimals(), 6);
    }

    function test_CollateralToken_immutables() public view {
        assertEq(collateral.token.usdc(), address(usdc));
        assertEq(collateral.token.usdce(), address(usdce));
        assertEq(collateral.token.vault(), collateral.vault);
    }

    /*--------------------------------------------------------------
                          ROLE MANAGEMENT
    --------------------------------------------------------------*/

    function test_CollateralToken_addMinter() public {
        vm.prank(owner);
        collateral.token.addMinter(alice);
        assertTrue(collateral.token.hasAllRoles(alice, 1 << 0));
    }

    function test_CollateralToken_removeMinter() public {
        vm.prank(owner);
        collateral.token.addMinter(alice);
        assertTrue(collateral.token.hasAllRoles(alice, 1 << 0));

        vm.prank(owner);
        collateral.token.removeMinter(alice);
        assertFalse(collateral.token.hasAllRoles(alice, 1 << 0));
    }

    function test_CollateralToken_addWrapper() public {
        vm.prank(owner);
        collateral.token.addWrapper(alice);
        assertTrue(collateral.token.hasAllRoles(alice, 1 << 1));
    }

    function test_CollateralToken_removeWrapper() public {
        vm.prank(owner);
        collateral.token.addWrapper(alice);
        assertTrue(collateral.token.hasAllRoles(alice, 1 << 1));

        vm.prank(owner);
        collateral.token.removeWrapper(alice);
        assertFalse(collateral.token.hasAllRoles(alice, 1 << 1));
    }

    function test_revert_CollateralToken_addMinter_unauthorized() public {
        vm.prank(brian);
        vm.expectRevert(Ownable.Unauthorized.selector);
        collateral.token.addMinter(brian);
    }

    function test_revert_CollateralToken_removeMinter_unauthorized() public {
        vm.prank(brian);
        vm.expectRevert(Ownable.Unauthorized.selector);
        collateral.token.removeMinter(brian);
    }

    function test_revert_CollateralToken_addWrapper_unauthorized() public {
        vm.prank(brian);
        vm.expectRevert(Ownable.Unauthorized.selector);
        collateral.token.addWrapper(brian);
    }

    function test_revert_CollateralToken_removeWrapper_unauthorized() public {
        vm.prank(brian);
        vm.expectRevert(Ownable.Unauthorized.selector);
        collateral.token.removeWrapper(brian);
    }

    /*--------------------------------------------------------------
                              MINT
    --------------------------------------------------------------*/

    function test_CollateralToken_mint() public {
        vm.prank(minter);
        collateral.token.mint(alice, amount);
        assertEq(collateral.token.balanceOf(alice), amount);
    }

    function test_revert_CollateralToken_mint_unauthorized() public {
        vm.prank(alice);
        vm.expectRevert(Ownable.Unauthorized.selector);
        collateral.token.mint(alice, amount);
    }

    /*--------------------------------------------------------------
                              BURN
    --------------------------------------------------------------*/

    function test_CollateralToken_burn() public {
        vm.prank(minter);
        collateral.token.mint(minter, amount);
        assertEq(collateral.token.balanceOf(minter), amount);

        vm.prank(minter);
        collateral.token.burn(amount);
        assertEq(collateral.token.balanceOf(minter), 0);
    }

    function test_revert_CollateralToken_burn_unauthorized() public {
        vm.prank(alice);
        vm.expectRevert(Ownable.Unauthorized.selector);
        collateral.token.burn(amount);
    }

    /*--------------------------------------------------------------
                          WRAP (with callback)
    --------------------------------------------------------------*/

    function test_CollateralToken_wrapUSDC() public {
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(router), amount);

        vm.expectEmit(true, true, true, true, address(collateral.token));
        emit Wrapped(address(router), address(usdc), brian, amount);

        router.wrap(address(usdc), brian, amount);
        vm.stopPrank();

        assertEq(usdc.balanceOf(alice), 0);
        assertEq(usdc.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(brian), amount);
    }

    function test_CollateralToken_wrapUSDCe() public {
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(router), amount);

        vm.expectEmit(true, true, true, true, address(collateral.token));
        emit Wrapped(address(router), address(usdce), brian, amount);

        router.wrap(address(usdce), brian, amount);
        vm.stopPrank();

        assertEq(usdce.balanceOf(alice), 0);
        assertEq(usdce.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(brian), amount);
    }

    /*--------------------------------------------------------------
                      WRAP (without callback)
    --------------------------------------------------------------*/

    function test_CollateralToken_wrapUSDC_noCallback() public {
        usdc.mint(address(collateral.token), amount);

        vm.prank(address(router));
        collateral.token.wrap(address(usdc), brian, amount, address(0), "");

        assertEq(usdc.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(brian), amount);
    }

    function test_CollateralToken_wrapUSDCe_noCallback() public {
        usdce.mint(address(collateral.token), amount);

        vm.prank(address(router));
        collateral.token.wrap(address(usdce), brian, amount, address(0), "");

        assertEq(usdce.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(brian), amount);
    }

    /*--------------------------------------------------------------
                        WRAP (revert cases)
    --------------------------------------------------------------*/

    function test_revert_CollateralToken_wrapInvalidAsset(address _invalidAsset) public {
        vm.assume(_invalidAsset != address(usdc) && _invalidAsset != address(usdce));

        vm.prank(address(router));
        vm.expectRevert(CollateralErrors.InvalidAsset.selector);
        collateral.token.wrap(_invalidAsset, brian, amount, address(0), "");
    }

    function test_revert_CollateralToken_wrap_unauthorized() public {
        vm.prank(alice);
        vm.expectRevert(Ownable.Unauthorized.selector);
        collateral.token.wrap(address(usdc), brian, amount, address(0), "");
    }

    /*--------------------------------------------------------------
                        UNWRAP (with callback)
    --------------------------------------------------------------*/

    function test_CollateralToken_unwrapUSDC() public {
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(router), amount);
        router.wrap(address(usdc), brian, amount);
        vm.stopPrank();

        vm.startPrank(brian);
        collateral.token.approve(address(router), amount);

        vm.expectEmit(true, true, true, true, address(collateral.token));
        emit Unwrapped(address(router), address(usdc), alice, amount);

        router.unwrap(address(usdc), alice, amount);
        vm.stopPrank();

        assertEq(usdc.balanceOf(alice), amount);
        assertEq(usdc.balanceOf(collateral.vault), 0);
        assertEq(collateral.token.balanceOf(brian), 0);
    }

    function test_CollateralToken_unwrapUSDCe() public {
        usdce.mint(alice, amount);

        vm.startPrank(alice);
        usdce.approve(address(router), amount);
        router.wrap(address(usdce), brian, amount);
        vm.stopPrank();

        vm.startPrank(brian);
        collateral.token.approve(address(router), amount);

        vm.expectEmit(true, true, true, true, address(collateral.token));
        emit Unwrapped(address(router), address(usdce), alice, amount);

        router.unwrap(address(usdce), alice, amount);
        vm.stopPrank();

        assertEq(usdce.balanceOf(alice), amount);
        assertEq(usdce.balanceOf(collateral.vault), 0);
        assertEq(collateral.token.balanceOf(brian), 0);
    }

    /*--------------------------------------------------------------
                    UNWRAP (without callback)
    --------------------------------------------------------------*/

    function test_CollateralToken_unwrapUSDC_noCallback() public {
        usdc.mint(alice, amount);

        vm.startPrank(alice);
        usdc.approve(address(router), amount);
        router.wrap(address(usdc), alice, amount);

        collateral.token.transfer(address(collateral.token), amount);
        vm.stopPrank();

        vm.prank(address(router));
        collateral.token.unwrap(address(usdc), brian, amount, address(0), "");

        assertEq(usdc.balanceOf(brian), amount);
        assertEq(collateral.token.balanceOf(brian), 0);
    }

    /*--------------------------------------------------------------
                      UNWRAP (revert cases)
    --------------------------------------------------------------*/

    function test_revert_CollateralToken_unwrapInvalidAsset(address _invalidAsset) public {
        vm.assume(_invalidAsset != address(usdc) && _invalidAsset != address(usdce));

        vm.prank(address(router));
        vm.expectRevert(CollateralErrors.InvalidAsset.selector);
        collateral.token.unwrap(_invalidAsset, brian, amount, address(0), "");
    }

    function test_revert_CollateralToken_unwrap_unauthorized() public {
        vm.prank(alice);
        vm.expectRevert(Ownable.Unauthorized.selector);
        collateral.token.unwrap(address(usdc), brian, amount, address(0), "");
    }

    /*--------------------------------------------------------------
                          PERMIT2
    --------------------------------------------------------------*/

    function test_CollateralToken_permit2NoInfiniteAllowance() public view {
        address permit2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
        assertEq(collateral.token.allowance(alice, permit2), 0);
    }

    /*--------------------------------------------------------------
                          UUPS UPGRADE
    --------------------------------------------------------------*/

    function test_CollateralToken_upgradeToAndCall() public {
        address newImpl = address(new CollateralToken(address(usdc), address(usdce), collateral.vault));

        vm.prank(owner);
        collateral.token.upgradeToAndCall(newImpl, "");
    }

    function test_revert_CollateralToken_upgradeToAndCall_unauthorized() public {
        address newImpl = address(new CollateralToken(address(usdc), address(usdce), collateral.vault));

        vm.prank(brian);
        vm.expectRevert(Ownable.Unauthorized.selector);
        collateral.token.upgradeToAndCall(newImpl, "");
    }
}
