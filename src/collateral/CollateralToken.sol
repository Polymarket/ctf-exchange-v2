// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

import { OwnableRoles } from "@solady/src/auth/OwnableRoles.sol";
import { ERC20 } from "@solady/src/tokens/ERC20.sol";
import { Initializable } from "@solady/src/utils/Initializable.sol";
import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";
import { UUPSUpgradeable } from "@solady/src/utils/UUPSUpgradeable.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";
import { ICollateralToken } from "./interfaces/ICollateralToken.sol";
import { ICollateralTokenCallbacks } from "./interfaces/ICollateralTokenCallbacks.sol";

abstract contract CollateralTokenEvents {
    /// @notice Emitted when an asset is wrapped into collateral
    /// @param caller Address that initiated the wrap
    /// @param asset The underlying asset address
    /// @param to Recipient of the minted collateral
    /// @param amount Amount of collateral minted
    event Wrapped(address indexed caller, address indexed asset, address indexed to, uint256 amount);

    /// @notice Emitted when collateral is unwrapped to an asset
    /// @param caller Address that initiated the unwrap
    /// @param asset The underlying asset address
    /// @param to Recipient of the unwrapped asset
    /// @param amount Amount of collateral burned
    event Unwrapped(address indexed caller, address indexed asset, address indexed to, uint256 amount);
}

/// @title CollateralToken
/// @author Polymarket
/// @notice ROLE_0: Minter/Burner
/// @notice ROLE_1: Wrapper/Unwrapper
contract CollateralToken is
    UUPSUpgradeable,
    Initializable,
    ERC20,
    OwnableRoles,
    CollateralErrors,
    CollateralTokenEvents,
    ICollateralToken
{
    using SafeTransferLib for address;

    /*--------------------------------------------------------------
                                 STATE
    --------------------------------------------------------------*/

    /// @notice Address of the native USDC token
    address public immutable USDC;

    /// @notice Address of the bridged USDC.e token
    address public immutable USDCE;

    /// @notice Address of the vault holding underlying assets
    address public immutable VAULT;

    /*--------------------------------------------------------------
                               CONSTANTS
    --------------------------------------------------------------*/

    /// @dev Role flag for mint/burn privileges
    uint256 internal constant MINTER_ROLE = _ROLE_0;

    /// @dev Role flag for wrap/unwrap privileges
    uint256 internal constant WRAPPER_ROLE = _ROLE_1;

    /*--------------------------------------------------------------
                               MODIFIERS
    --------------------------------------------------------------*/

    /// @dev Reverts if the asset is not USDC or USDC.e
    modifier onlyValidAsset(address _asset) {
        require(_asset == USDC || _asset == USDCE, InvalidAsset());
        _;
    }

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    /// @notice Deploys the CollateralToken implementation
    /// @param _usdc Address of the native USDC token
    /// @param _usdce Address of the bridged USDC.e token
    /// @param _vault Address of the vault for underlying assets
    constructor(address _usdc, address _usdce, address _vault) {
        USDC = _usdc;
        USDCE = _usdce;
        VAULT = _vault;

        _disableInitializers();
    }

    /*--------------------------------------------------------------
                              INITIALIZE
    --------------------------------------------------------------*/

    /// @notice Initializes the contract with the given owner.
    /// @dev This replaces the constructor for upgradeable contracts.
    /// @param _owner The address to set as the owner of the contract.
    function initialize(address _owner) external initializer {
        _initializeOwner(_owner);
    }

    /*--------------------------------------------------------------
                                  VIEW
    --------------------------------------------------------------*/

    /// @notice Returns the token name
    /// @return The token name string
    function name() public pure override returns (string memory) {
        return "Polymarket USD";
    }

    /// @notice Returns the token symbol
    /// @return The token symbol string
    function symbol() public pure override returns (string memory) {
        return "pUSD";
    }

    /// @notice Returns the token decimal precision
    /// @return The number of decimals (6)
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /*--------------------------------------------------------------
                               EXTERNAL
    --------------------------------------------------------------*/

    /// @notice Mints a new collateral token
    /// @param _to The address to mint the collateral token to
    /// @param _amount The amount of collateral token to mint
    /// @dev The caller must have the MINTER_ROLE
    function mint(address _to, uint256 _amount) external onlyRoles(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    /// @notice Burns a collateral token
    /// @param _amount The amount of collateral token to burn
    /// @dev The caller must have the MINTER_ROLE
    function burn(uint256 _amount) external onlyRoles(MINTER_ROLE) {
        _burn(msg.sender, _amount);
    }

    /// @notice Wraps a supported asset into the collateral token
    /// @param _asset The asset to wrap
    /// @param _to The address to wrap the asset to
    /// @param _amount The amount of asset to wrap
    /// @param _callbackReceiver Address to receive the callback, or address(0) to skip callback
    /// @param _data Callback data
    /// @notice The asset must be a supported asset
    /// @dev The caller must have the WRAPPER_ROLE
    /// @dev The asset must be transferred into this contract either before calling this function or
    ///      in the callback
    function wrap(address _asset, address _to, uint256 _amount, address _callbackReceiver, bytes calldata _data)
        external
        onlyRoles(WRAPPER_ROLE)
        onlyValidAsset(_asset)
    {
        // mint
        _mint(_to, _amount);

        // callback (skip if address(0))
        if (_callbackReceiver != address(0)) {
            ICollateralTokenCallbacks(_callbackReceiver).wrapCallback(_asset, _to, _amount, _data);
        }

        // transfer asset to the vault
        _asset.safeTransfer(VAULT, _amount);

        emit Wrapped(msg.sender, _asset, _to, _amount);
    }

    /// @notice Unwraps a supported asset from the collateral token
    /// @param _asset The asset to unwrap
    /// @param _to The address to unwrap the asset to
    /// @param _amount The amount of asset to unwrap
    /// @param _callbackReceiver Address to receive the callback, or address(0) to skip callback
    /// @param _data Callback data
    /// @notice The asset must be a supported asset
    /// @dev The caller must have the WRAPPER_ROLE
    /// @dev The asset must be transferred into this contract either before calling this function or
    ///      in the callback
    function unwrap(address _asset, address _to, uint256 _amount, address _callbackReceiver, bytes calldata _data)
        external
        onlyRoles(WRAPPER_ROLE)
        onlyValidAsset(_asset)
    {
        // transfer asset from the vault
        _asset.safeTransferFrom(VAULT, _to, _amount);

        // callback (skip if address(0))
        if (_callbackReceiver != address(0)) {
            ICollateralTokenCallbacks(_callbackReceiver).unwrapCallback(_asset, _to, _amount, _data);
        }

        // burn
        _burn(address(this), _amount);

        emit Unwrapped(msg.sender, _asset, _to, _amount);
    }

    /*--------------------------------------------------------------
                            ROLE MANAGEMENT
    --------------------------------------------------------------*/

    /// @notice Grants minter role to an address
    /// @param _minter Address to grant minter role
    function addMinter(address _minter) external onlyOwner {
        _grantRoles(_minter, MINTER_ROLE);
    }

    /// @notice Revokes minter role from an address
    /// @param _minter Address to revoke minter role from
    function removeMinter(address _minter) external onlyOwner {
        _removeRoles(_minter, MINTER_ROLE);
    }

    /// @notice Grants wrapper role to an address
    /// @param _wrapper Address to grant wrapper role
    function addWrapper(address _wrapper) external onlyOwner {
        _grantRoles(_wrapper, WRAPPER_ROLE);
    }

    /// @notice Revokes wrapper role from an address
    /// @param _wrapper Address to revoke wrapper role from
    function removeWrapper(address _wrapper) external onlyOwner {
        _removeRoles(_wrapper, WRAPPER_ROLE);
    }

    /*--------------------------------------------------------------
                           SOLADY OVERRIDES
    --------------------------------------------------------------*/

    /// @dev Disables Permit2 infinite allowance
    /// @return Always returns false
    function _givePermit2InfiniteAllowance() internal pure override returns (bool) {
        return false;
    }

    /*--------------------------------------------------------------
                          UUPS UPGRADE AUTHORIZATION
    --------------------------------------------------------------*/

    /// @dev Authorizes an upgrade to a new implementation.
    /// @dev Only the owner can authorize upgrades.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
