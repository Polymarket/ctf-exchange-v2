// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { OwnableRoles } from "lib/solady/src/auth/OwnableRoles.sol";
import { ECDSA } from "lib/solady/src/utils/ECDSA.sol";
import { EIP712 } from "lib/solady/src/utils/EIP712.sol";
import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";
import { Pausable } from "./abstract/Pausable.sol";

import { CollateralToken } from "./CollateralToken.sol";

/// @title PermissionedRamp
/// @author Polymarket
/// @notice Permissioned wrap/unwrap for the PolymarketCollateralToken using EIP-712 witness signatures
/// @notice ADMIN_ROLE: Admin
/// @notice WITNESS_ROLE: Witness
contract PermissionedRamp is OwnableRoles, CollateralErrors, Pausable, EIP712 {
    using SafeTransferLib for address;

    /*--------------------------------------------------------------
                                 STATE
    --------------------------------------------------------------*/

    address public immutable collateralToken;

    mapping(address => uint256) public nonces;

    /*--------------------------------------------------------------
                               CONSTANTS
    --------------------------------------------------------------*/

    uint256 internal constant WITNESS_ROLE = _ROLE_1;

    bytes32 internal constant _WRAP_TYPEHASH =
        keccak256("Wrap(address sender,address asset,address to,uint256 amount,uint256 nonce,uint256 deadline)");

    bytes32 internal constant _UNWRAP_TYPEHASH =
        keccak256("Unwrap(address sender,address asset,address to,uint256 amount,uint256 nonce,uint256 deadline)");

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    constructor(address _owner, address _admin, address _collateralToken) {
        collateralToken = _collateralToken;

        _initializeOwner(_owner);
        _grantRoles(_admin, ADMIN_ROLE);
    }

    /*--------------------------------------------------------------
                                EXTERNAL
    --------------------------------------------------------------*/

    /// @notice Wraps a supported asset into the collateral token
    /// @param _asset The asset to wrap
    /// @param _to The address to wrap the asset to
    /// @param _amount The amount of asset to wrap
    /// @param _nonce The sender's current nonce
    /// @param _deadline The deadline for the witness signature
    /// @param _signature The witness signature
    /// @dev The asset must not be paused
    /// @dev The signature must be from a valid witness over the EIP-712 Wrap struct
    function wrap(
        address _asset,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline,
        bytes calldata _signature
    ) external onlyUnpaused(_asset) {
        _validateSignature(_WRAP_TYPEHASH, _asset, _to, _amount, _nonce, _deadline, _signature);
        _asset.safeTransferFrom(msg.sender, collateralToken, _amount);
        CollateralToken(collateralToken).wrap(_asset, _to, _amount, address(0), "");
    }

    /// @notice Unwraps a supported asset from the collateral token
    /// @param _asset The asset to unwrap
    /// @param _to The address to unwrap the asset to
    /// @param _amount The amount of asset to unwrap
    /// @param _nonce The sender's current nonce
    /// @param _deadline The deadline for the witness signature
    /// @param _signature The witness signature
    /// @dev The asset must not be paused
    /// @dev The signature must be from a valid witness over the EIP-712 Unwrap struct
    function unwrap(
        address _asset,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline,
        bytes calldata _signature
    ) external onlyUnpaused(_asset) {
        _validateSignature(_UNWRAP_TYPEHASH, _asset, _to, _amount, _nonce, _deadline, _signature);
        collateralToken.safeTransferFrom(msg.sender, collateralToken, _amount);
        CollateralToken(collateralToken).unwrap(_asset, _to, _amount, address(0), "");
    }

    /*--------------------------------------------------------------
                               ONLY ADMIN
    --------------------------------------------------------------*/

    /// @notice Adds a new admin to the contract
    /// @param _admin The address of the new admin
    function addAdmin(address _admin) external onlyRoles(ADMIN_ROLE) {
        _grantRoles(_admin, ADMIN_ROLE);
    }

    /// @notice Removes an admin from the contract
    /// @param _admin The address of the admin to remove
    function removeAdmin(address _admin) external onlyRoles(ADMIN_ROLE) {
        _removeRoles(_admin, ADMIN_ROLE);
    }

    /// @notice Adds a new witness to the contract
    /// @param _witness The address of the new witness
    function addWitness(address _witness) external onlyRoles(ADMIN_ROLE) {
        _grantRoles(_witness, WITNESS_ROLE);
    }

    /// @notice Removes a witness from the contract
    /// @param _witness The address of the witness to remove
    function removeWitness(address _witness) external onlyRoles(ADMIN_ROLE) {
        _removeRoles(_witness, WITNESS_ROLE);
    }

    /*--------------------------------------------------------------
                               INTERNAL
    --------------------------------------------------------------*/

    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "PermissionedRamp";
        version = "1";
    }

    function _validateSignature(
        bytes32 _typehash,
        address _asset,
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline,
        bytes calldata _signature
    ) internal {
        require(block.timestamp <= _deadline, ExpiredDeadline());
        require(_nonce == nonces[msg.sender]++, InvalidNonce());

        bytes32 structHash = keccak256(abi.encode(_typehash, msg.sender, _asset, _to, _amount, _nonce, _deadline));
        bytes32 digest = _hashTypedData(structHash);

        address witness = ECDSA.recoverCalldata(digest, _signature);
        require(hasAnyRole(witness, WITNESS_ROLE), InvalidSignature());
    }
}
