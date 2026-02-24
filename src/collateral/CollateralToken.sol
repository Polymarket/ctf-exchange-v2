// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { OwnableRoles } from "lib/solady/src/auth/OwnableRoles.sol";
import { ERC20 } from "lib/solady/src/tokens/ERC20.sol";
import { Initializable } from "lib/solady/src/utils/Initializable.sol";
import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";
import { UUPSUpgradeable } from "lib/solady/src/utils/UUPSUpgradeable.sol";

import { CollateralErrors } from "./abstract/CollateralErrors.sol";
import { ICollateralToken } from "./interfaces/ICollateralToken.sol";
import { ICollateralTokenCallbacks } from "./interfaces/ICollateralTokenCallbacks.sol";

abstract contract CollateralTokenEvents {
    /// @notice Emitted when a supported asset is wrapped into collateral tokens.
    event Wrapped(address indexed caller, address indexed asset, address indexed to, uint256 amount);

    /// @notice Emitted when collateral tokens are unwrapped back into a supported asset.
    event Unwrapped(address indexed caller, address indexed asset, address indexed to, uint256 amount);
}

/// @title CollateralToken
/// @author Polymarket
/// @notice ERC20 collateral token backed by USDC/USDCe, deployed behind a UUPS proxy.
/// @dev Roles: ROLE_0 = Minter/Burner, ROLE_1 = Wrapper/Unwrapper. Managed by the owner.
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

    /// @notice The USDC token address accepted for wrapping/unwrapping.
    address public immutable usdc;

    /// @notice The bridged USDC (USDCe) token address accepted for wrapping/unwrapping.
    address public immutable usdce;

    /// @notice The vault address that custodies the underlying assets.
    address public immutable vault;

    /*--------------------------------------------------------------
                               CONSTANTS
    --------------------------------------------------------------*/

    /// @dev Role for minting and burning collateral tokens.
    uint256 internal constant MINTER_ROLE = _ROLE_0;

    /// @dev Role for wrapping and unwrapping supported assets.
    uint256 internal constant WRAPPER_ROLE = _ROLE_1;

    /*--------------------------------------------------------------
                               MODIFIERS
    --------------------------------------------------------------*/

    /// @dev Reverts with `InvalidAsset()` if `_asset` is not USDC or USDCe.
    modifier onlyValidAsset(address _asset) {
        require(_asset == usdc || _asset == usdce, InvalidAsset());
        _;
    }

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    /// @notice Sets immutable references and disables initializers on the implementation.
    /// @param _usdc The USDC token address.
    /// @param _usdce The bridged USDC (USDCe) token address.
    /// @param _vault The vault address that will custody the underlying assets.
    constructor(address _usdc, address _usdce, address _vault) {
        usdc = _usdc;
        usdce = _usdce;
        vault = _vault;

        _disableInitializers();
    }

    /*--------------------------------------------------------------
                             INITIALIZER
    --------------------------------------------------------------*/

    /// @notice Initializes the proxy with the given owner.
    /// @dev This replaces the constructor for upgradeable contracts.
    /// @param _owner The address to set as the owner of the contract.
    function initialize(address _owner) external initializer {
        _initializeOwner(_owner);
    }

    /*--------------------------------------------------------------
                                  VIEW
    --------------------------------------------------------------*/

    /// @notice Returns the token name.
    function name() public pure override returns (string memory) {
        return "PolyMarketCollateralToken";
    }

    /// @notice Returns the token symbol.
    function symbol() public pure override returns (string memory) {
        return "PMCT";
    }

    /// @notice Returns the number of decimals (6, matching USDC).
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /*--------------------------------------------------------------
                             EXTERNAL
    --------------------------------------------------------------*/

    /// @notice Mints collateral tokens to `_to`.
    /// @param _to The address to receive the minted tokens.
    /// @param _amount The amount of tokens to mint.
    /// @dev The caller must have the MINTER_ROLE.
    function mint(address _to, uint256 _amount) external onlyRoles(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    /// @notice Burns collateral tokens from the caller.
    /// @param _amount The amount of tokens to burn.
    /// @dev The caller must have the MINTER_ROLE.
    function burn(uint256 _amount) external onlyRoles(MINTER_ROLE) {
        _burn(msg.sender, _amount);
    }

    /// @notice Wraps a supported asset into collateral tokens.
    /// @param _asset The asset to wrap (must be USDC or USDCe).
    /// @param _to The address to receive the minted collateral tokens.
    /// @param _amount The amount of asset to wrap.
    /// @param _callbackReceiver Address to receive the callback, or address(0) to skip.
    /// @param _data Arbitrary data passed to the callback receiver.
    /// @dev The caller must have the WRAPPER_ROLE.
    /// @dev The asset must be transferred into this contract either before calling this function
    ///      or in the callback.
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

    /// @notice Unwraps collateral tokens back into a supported asset.
    /// @param _asset The asset to receive (must be USDC or USDCe).
    /// @param _to The address to receive the unwrapped asset.
    /// @param _amount The amount of collateral tokens to unwrap.
    /// @param _callbackReceiver Address to receive the callback, or address(0) to skip.
    /// @param _data Arbitrary data passed to the callback receiver.
    /// @dev The caller must have the WRAPPER_ROLE.
    /// @dev The collateral tokens must be transferred into this contract either before calling
    ///      this function or in the callback.
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

    /// @notice Grants the minter role to an address.
    /// @param _minter The address to grant the minter role to.
    function addMinter(address _minter) external onlyOwner {
        _grantRoles(_minter, MINTER_ROLE);
    }

    /// @notice Revokes the minter role from an address.
    /// @param _minter The address to revoke the minter role from.
    function removeMinter(address _minter) external onlyOwner {
        _removeRoles(_minter, MINTER_ROLE);
    }

    /// @notice Grants the wrapper role to an address.
    /// @param _wrapper The address to grant the wrapper role to.
    function addWrapper(address _wrapper) external onlyOwner {
        _grantRoles(_wrapper, WRAPPER_ROLE);
    }

    /// @notice Revokes the wrapper role from an address.
    /// @param _wrapper The address to revoke the wrapper role from.
    function removeWrapper(address _wrapper) external onlyOwner {
        _removeRoles(_wrapper, WRAPPER_ROLE);
    }

    /*--------------------------------------------------------------
                           SOLADY OVERRIDES
    --------------------------------------------------------------*/

    /// @dev Disables Solady's default Permit2 infinite allowance.
    function _givePermit2InfiniteAllowance() internal view override returns (bool) {
        return false;
    }

    /*--------------------------------------------------------------
                          UUPS UPGRADE AUTHORIZATION
    --------------------------------------------------------------*/

    /// @dev Authorizes an upgrade to a new implementation. Only the owner can upgrade.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
