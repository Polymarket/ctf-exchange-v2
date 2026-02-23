// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { TestHelper } from "src/test/dev/TestHelper.sol";

import { CollateralErrors } from "src/collateral/abstract/CollateralErrors.sol";
import { PermissionedRamp } from "src/collateral/PermissionedRamp.sol";
import { Collateral, CollateralSetup, USDC, USDCe } from "src/test/dev/CollateralSetup.sol";

contract PermissionedRampTest is TestHelper {
    error Unauthorized();

    address owner = alice;

    uint256 witnessKey = 0xA11CE;
    address witness;

    Collateral collateral;
    USDC usdc;
    USDCe usdce;

    function setUp() public {
        witness = vm.addr(witnessKey);

        collateral = CollateralSetup._deploy(owner);
        usdc = collateral.usdc;
        usdce = collateral.usdce;

        vm.prank(owner);
        collateral.permissionedRamp.addWitness(witness);
    }

    // --- helpers ---

    function _signWrap(address _sender, address _asset, address _to, uint256 _amount, uint256 _nonce, uint256 _deadline)
        internal
        view
        returns (bytes memory)
    {
        return _signWrap(witnessKey, _sender, _asset, _to, _amount, _nonce, _deadline);
    }

    function _signWrap(
        uint256 _key,
        address _sender,
        address _asset,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Wrap(address sender,address asset,address to,uint256 amount,uint256 nonce,uint256 deadline)"
                ),
                _sender,
                _asset,
                _to,
                _amount,
                _nonce,
                _deadline
            )
        );
        bytes32 digest = _hashTypedData(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, digest);
        return abi.encodePacked(r, s, v);
    }

    function _signUnwrap(
        address _sender,
        address _asset,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline
    ) internal view returns (bytes memory) {
        return _signUnwrap(witnessKey, _sender, _asset, _to, _amount, _nonce, _deadline);
    }

    function _signUnwrap(
        uint256 _key,
        address _sender,
        address _asset,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Unwrap(address sender,address asset,address to,uint256 amount,uint256 nonce,uint256 deadline)"
                ),
                _sender,
                _asset,
                _to,
                _amount,
                _nonce,
                _deadline
            )
        );
        bytes32 digest = _hashTypedData(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, digest);
        return abi.encodePacked(r, s, v);
    }

    function _hashTypedData(bytes32 structHash) internal view returns (bytes32) {
        (, string memory name, string memory version, uint256 chainId, address verifyingContract,,) =
            collateral.permissionedRamp.eip712Domain();

        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                verifyingContract
            )
        );

        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    // --- wrap ---

    function test_PermissionedRamp_wrapUSDC() public {
        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        usdc.mint(brian, amount);

        bytes memory sig = _signWrap(brian, address(usdc), brian, amount, 0, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, sig);
        vm.stopPrank();

        assertEq(usdc.balanceOf(brian), 0);
        assertEq(usdc.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(brian), amount);
    }

    function test_PermissionedRamp_wrapUSDCe() public {
        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        usdce.mint(brian, amount);

        bytes memory sig = _signWrap(brian, address(usdce), brian, amount, 0, deadline);

        vm.startPrank(brian);
        usdce.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdce), brian, amount, 0, deadline, sig);
        vm.stopPrank();

        assertEq(usdce.balanceOf(brian), 0);
        assertEq(usdce.balanceOf(collateral.vault), amount);
        assertEq(collateral.token.balanceOf(brian), amount);
    }

    function test_PermissionedRamp_wrap_incrementsNonce() public {
        uint256 amount = 50_000_000;
        uint256 deadline = block.timestamp + 1 hours;

        usdc.mint(brian, amount * 2);

        bytes memory sig0 = _signWrap(brian, address(usdc), brian, amount, 0, deadline);
        bytes memory sig1 = _signWrap(brian, address(usdc), brian, amount, 1, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount * 2);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, sig0);
        assertEq(collateral.permissionedRamp.nonces(brian), 1);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 1, deadline, sig1);
        assertEq(collateral.permissionedRamp.nonces(brian), 2);
        vm.stopPrank();

        assertEq(collateral.token.balanceOf(brian), amount * 2);
    }

    // --- unwrap ---

    function test_PermissionedRamp_unwrapUSDC() public {
        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        usdc.mint(brian, amount);

        bytes memory wrapSig = _signWrap(brian, address(usdc), brian, amount, 0, deadline);
        bytes memory unwrapSig = _signUnwrap(brian, address(usdc), brian, amount, 1, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, wrapSig);

        collateral.token.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.unwrap(address(usdc), brian, amount, 1, deadline, unwrapSig);
        vm.stopPrank();

        assertEq(usdc.balanceOf(brian), amount);
        assertEq(usdc.balanceOf(collateral.vault), 0);
        assertEq(collateral.token.balanceOf(brian), 0);
    }

    function test_PermissionedRamp_unwrapUSDCe() public {
        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        usdce.mint(brian, amount);

        bytes memory wrapSig = _signWrap(brian, address(usdce), brian, amount, 0, deadline);
        bytes memory unwrapSig = _signUnwrap(brian, address(usdce), brian, amount, 1, deadline);

        vm.startPrank(brian);
        usdce.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdce), brian, amount, 0, deadline, wrapSig);

        collateral.token.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.unwrap(address(usdce), brian, amount, 1, deadline, unwrapSig);
        vm.stopPrank();

        assertEq(usdce.balanceOf(brian), amount);
        assertEq(usdce.balanceOf(collateral.vault), 0);
        assertEq(collateral.token.balanceOf(brian), 0);
    }

    // --- invalid signature ---

    function test_revert_PermissionedRamp_wrap_invalidWitness() public {
        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 badKey = 0xBAD;
        usdc.mint(brian, amount);

        bytes memory sig = _signWrap(badKey, brian, address(usdc), brian, amount, 0, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(CollateralErrors.InvalidSignature.selector);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, sig);
        vm.stopPrank();
    }

    function test_revert_PermissionedRamp_unwrap_invalidWitness() public {
        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 badKey = 0xBAD;
        usdc.mint(brian, amount);

        bytes memory wrapSig = _signWrap(brian, address(usdc), brian, amount, 0, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, wrapSig);

        bytes memory unwrapSig = _signUnwrap(badKey, brian, address(usdc), brian, amount, 1, deadline);

        collateral.token.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(CollateralErrors.InvalidSignature.selector);
        collateral.permissionedRamp.unwrap(address(usdc), brian, amount, 1, deadline, unwrapSig);
        vm.stopPrank();
    }

    // --- invalid nonce ---

    function test_revert_PermissionedRamp_wrap_invalidNonce() public {
        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        usdc.mint(brian, amount);

        bytes memory sig = _signWrap(brian, address(usdc), brian, amount, 1, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(CollateralErrors.InvalidNonce.selector);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 1, deadline, sig);
        vm.stopPrank();
    }

    // --- replay ---

    function test_revert_PermissionedRamp_wrap_replaySignature() public {
        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        usdc.mint(brian, amount * 2);

        bytes memory sig = _signWrap(brian, address(usdc), brian, amount, 0, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount * 2);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, sig);

        // Replay with same nonce fails
        vm.expectRevert(CollateralErrors.InvalidNonce.selector);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, sig);
        vm.stopPrank();
    }

    // --- expired deadline ---

    function test_revert_PermissionedRamp_wrap_expiredDeadline() public {
        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp - 1;
        usdc.mint(brian, amount);

        bytes memory sig = _signWrap(brian, address(usdc), brian, amount, 0, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(CollateralErrors.ExpiredDeadline.selector);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, sig);
        vm.stopPrank();
    }

    function test_revert_PermissionedRamp_unwrap_expiredDeadline() public {
        uint256 amount = 100_000_000;
        uint256 wrapDeadline = block.timestamp + 1 hours;
        usdc.mint(brian, amount);

        bytes memory wrapSig = _signWrap(brian, address(usdc), brian, amount, 0, wrapDeadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, wrapDeadline, wrapSig);

        uint256 expiredDeadline = block.timestamp - 1;
        bytes memory unwrapSig = _signUnwrap(brian, address(usdc), brian, amount, 1, expiredDeadline);

        collateral.token.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(CollateralErrors.ExpiredDeadline.selector);
        collateral.permissionedRamp.unwrap(address(usdc), brian, amount, 1, expiredDeadline, unwrapSig);
        vm.stopPrank();
    }

    // --- pause ---

    function test_revert_PermissionedRamp_wrap_paused() public {
        vm.prank(owner);
        collateral.permissionedRamp.pause(address(usdc));

        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        usdc.mint(brian, amount);

        bytes memory sig = _signWrap(brian, address(usdc), brian, amount, 0, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, sig);
        vm.stopPrank();
    }

    function test_revert_PermissionedRamp_unwrap_paused() public {
        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        usdc.mint(brian, amount);

        bytes memory wrapSig = _signWrap(brian, address(usdc), brian, amount, 0, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, wrapSig);
        vm.stopPrank();

        vm.prank(owner);
        collateral.permissionedRamp.pause(address(usdc));

        bytes memory unwrapSig = _signUnwrap(brian, address(usdc), brian, amount, 1, deadline);

        vm.startPrank(brian);
        collateral.token.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(CollateralErrors.OnlyUnpaused.selector);
        collateral.permissionedRamp.unwrap(address(usdc), brian, amount, 1, deadline, unwrapSig);
        vm.stopPrank();
    }

    // --- admin ---

    function test_PermissionedRamp_addWitness() public {
        uint256 newWitnessKey = 0xBEEF;
        address newWitness = vm.addr(newWitnessKey);

        vm.prank(owner);
        collateral.permissionedRamp.addWitness(newWitness);

        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        usdc.mint(brian, amount);

        bytes memory sig = _signWrap(newWitnessKey, brian, address(usdc), brian, amount, 0, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, sig);
        vm.stopPrank();

        assertEq(collateral.token.balanceOf(brian), amount);
    }

    function test_PermissionedRamp_removeWitness() public {
        vm.prank(owner);
        collateral.permissionedRamp.removeWitness(witness);

        uint256 amount = 100_000_000;
        uint256 deadline = block.timestamp + 1 hours;
        usdc.mint(brian, amount);

        bytes memory sig = _signWrap(brian, address(usdc), brian, amount, 0, deadline);

        vm.startPrank(brian);
        usdc.approve(address(collateral.permissionedRamp), amount);
        vm.expectRevert(CollateralErrors.InvalidSignature.selector);
        collateral.permissionedRamp.wrap(address(usdc), brian, amount, 0, deadline, sig);
        vm.stopPrank();
    }
}
