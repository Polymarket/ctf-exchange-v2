// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

import { OwnableRoles } from "@solady/src/auth/OwnableRoles.sol";
import { ECDSA } from "@solady/src/utils/ECDSA.sol";
import { EIP712 } from "@solady/src/utils/EIP712.sol";
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";
import { Pausable } from "./abstract/Pausable.sol";

import { CollateralToken } from "./CollateralToken.sol";

/// @title PermissionedRamp
/// @author Polymarket
/// @notice Permissioned wrap/unwrap for the PolymarketCollateralToken using EIP-712 witness
/// signatures
/// @notice ADMIN_ROLE: Admin
/// @notice WITNESS_ROLE: Witness
contract PermissionedRamp is OwnableRoles, CollateralErrors, Pausable, EIP712 {
    using SafeTransferLib for address;

    /*--------------------------------------------------------------
                                 STATE
    --------------------------------------------------------------*/

    /// @notice The collateral token address.
    address public immutable COLLATERAL_TOKEN;

    /// @notice Per-sender nonce for replay protection.
    mapping(address => uint256) public nonces;

    /*--------------------------------------------------------------
                               CONSTANTS
    --------------------------------------------------------------*/

    /// @dev Witness role for signing wrap/unwrap approvals.
    uint256 internal constant WITNESS_ROLE = _ROLE_1;

    /// @dev EIP-712 typehash for the Wrap struct.
    bytes32 internal constant _WRAP_TYPEHASH =
        keccak256("Wrap(address sender,address asset,address to,uint256 amount,uint256 nonce,uint256 deadline)");

    /// @dev EIP-712 typehash for the Unwrap struct.
    bytes32 internal constant _UNWRAP_TYPEHASH =
        keccak256("Unwrap(address sender,address asset,address to,uint256 amount,uint256 nonce,uint256 deadline)");

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    /// @notice Deploys the permissioned ramp contract.
    /// @param _owner The contract owner.
    /// @param _admin The initial admin address.
    /// @param _collateralToken The collateral token address.
    constructor(address _owner, address _admin, address _collateralToken) {
        COLLATERAL_TOKEN = _collateralToken;

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
        _validateSignature({
            _typehash: _WRAP_TYPEHASH,
            _asset: _asset,
            _to: _to,
            _amount: _amount,
            _nonce: _nonce,
            _deadline: _deadline,
            _signature: _signature
        });
        _asset.safeTransferFrom(msg.sender, COLLATERAL_TOKEN, _amount);
        // forgefmt: disable-next-item
        CollateralToken(COLLATERAL_TOKEN).wrap({
            _asset: _asset,
            _to: _to,
            _amount: _amount,
            _callbackReceiver: address(0),
            _data: ""
        });
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
        _validateSignature({
            _typehash: _UNWRAP_TYPEHASH,
            _asset: _asset,
            _to: _to,
            _amount: _amount,
            _nonce: _nonce,
            _deadline: _deadline,
            _signature: _signature
        });
        COLLATERAL_TOKEN.safeTransferFrom(msg.sender, COLLATERAL_TOKEN, _amount);
        // forgefmt: disable-next-item
        CollateralToken(COLLATERAL_TOKEN).unwrap({
            _asset: _asset,
            _to: _to,
            _amount: _amount,
            _callbackReceiver: address(0),
            _data: ""
        });
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

    /// @dev Returns the EIP-712 domain name and version.
    /// @return name The domain name.
    /// @return version The domain version.
    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "PermissionedRamp";
        version = "1";
    }

    /// @dev Validates the witness signature and increments the nonce.
    /// @param _typehash The EIP-712 typehash (wrap or unwrap).
    /// @param _asset The asset address.
    /// @param _to The recipient address.
    /// @param _amount The amount.
    /// @param _nonce The expected sender nonce.
    /// @param _deadline The signature expiry timestamp.
    /// @param _signature The witness ECDSA signature.
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
