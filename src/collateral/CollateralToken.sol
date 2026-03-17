// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { OwnableRoles } from "lib/solady/src/auth/OwnableRoles.sol";
import { ERC20 } from "lib/solady/src/tokens/ERC20.sol";
import { Initializable } from "lib/solady/src/utils/Initializable.sol";
import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";
import { UUPSUpgradeable } from "lib/solady/src/utils/UUPSUpgradeable.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";
import { ICollateralToken } from "./interfaces/ICollateralToken.sol";
import { ICollateralTokenCallbacks } from "./interfaces/ICollateralTokenCallbacks.sol";

abstract contract CollateralTokenEvents {
    event Wrapped(address indexed caller, address indexed asset, address indexed to, uint256 amount);
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

    address public immutable usdc;
    address public immutable usdce;
    address public immutable vault;

    /*--------------------------------------------------------------
                               CONSTANTS
    --------------------------------------------------------------*/

    uint256 internal constant MINTER_ROLE = _ROLE_0;
    uint256 internal constant WRAPPER_ROLE = _ROLE_1;

    /*--------------------------------------------------------------
                               MODIFIERS
    --------------------------------------------------------------*/

    modifier onlyValidAsset(address _asset) {
        require(_asset == usdc || _asset == usdce, InvalidAsset());
        _;
    }

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    constructor(address _usdc, address _usdce, address _vault) {
        usdc = _usdc;
        usdce = _usdce;
        vault = _vault;

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

    function name() public pure override returns (string memory) {
        return "PolyMarketCollateralToken";
    }

    function symbol() public pure override returns (string memory) {
        return "PMCT";
    }

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
        _asset.safeTransfer(vault, _amount);

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
        _asset.safeTransferFrom(vault, _to, _amount);

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

    function addMinter(address _minter) external onlyOwner {
        _grantRoles(_minter, MINTER_ROLE);
    }

    function removeMinter(address _minter) external onlyOwner {
        _removeRoles(_minter, MINTER_ROLE);
    }

    function addWrapper(address _wrapper) external onlyOwner {
        _grantRoles(_wrapper, WRAPPER_ROLE);
    }

    function removeWrapper(address _wrapper) external onlyOwner {
        _removeRoles(_wrapper, WRAPPER_ROLE);
    }

    /*--------------------------------------------------------------
                           SOLADY OVERRIDES
    --------------------------------------------------------------*/

    function _givePermit2InfiniteAllowance() internal view override returns (bool) {
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
