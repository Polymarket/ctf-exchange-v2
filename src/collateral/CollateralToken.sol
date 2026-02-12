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
    event Wrapped(address indexed caller, address indexed asset, address indexed to, uint256 amount);
    event Unwrapped(address indexed caller, address indexed asset, address indexed to, uint256 amount);
}

/// @title CollateralToken
/// @author Polymarket
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

    address public immutable usdc;
    address public immutable usdce;
    address public immutable vault;

    modifier onlyValidAsset(address _asset) {
        require(_asset == usdc || _asset == usdce, InvalidAsset());
        _;
    }

    constructor(address _usdc, address _usdce, address _vault) {
        usdc = _usdc;
        usdce = _usdce;
        vault = _vault;

        _disableInitializers();
    }

    /// @notice Initializes the contract with the given owner.
    /// @dev This replaces the constructor for upgradeable contracts.
    /// @param _owner The address to set as the owner of the contract.
    function initialize(address _owner) external initializer {
        _initializeOwner(_owner);
    }

    function name() public pure override returns (string memory) {
        return "PolyMarketCollateralToken";
    }

    function symbol() public pure override returns (string memory) {
        return "PMCT";
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// @notice Wraps a supported asset into the collateral token
    /// @param _asset The asset to wrap
    /// @param _to The address to wrap the asset to
    /// @param _amount The amount of asset to wrap
    /// @notice The asset must be a supported asset
    /// @dev The caller must have the ROLE_1 role
    /// @dev The asset must be transferred into this contract either before calling this function or
    ///      in the callback
    function wrap(address _asset, address _to, uint256 _amount, bytes calldata _data)
        external
        onlyRoles(_ROLE_1)
        onlyValidAsset(_asset)
    {
        // mint
        _mint(_to, _amount);

        // callback
        ICollateralTokenCallbacks(msg.sender).wrapCallback(_asset, _to, _amount, _data);

        // transfer asset to the vault
        _asset.safeTransfer(vault, _amount);

        emit Wrapped(msg.sender, _asset, _to, _amount);
    }

    /// @notice Unwraps a supported asset from the collateral token
    /// @param _asset The asset to unwrap
    /// @param _to The address to unwrap the asset to
    /// @param _amount The amount of asset to unwrap
    /// @notice The asset must be a supported asset
    /// @dev The caller must have the ROLE_1 role
    /// @dev The asset must be transferred into this contract either before calling this function or
    ///      in the callback
    function unwrap(address _asset, address _to, uint256 _amount, bytes calldata _data)
        external
        onlyRoles(_ROLE_1)
        onlyValidAsset(_asset)
    {
        // transfer asset from the vault
        _asset.safeTransferFrom(vault, _to, _amount);

        // callback
        ICollateralTokenCallbacks(msg.sender).unwrapCallback(_asset, _to, _amount, _data);

        // burn
        _burn(address(this), _amount);

        emit Unwrapped(msg.sender, _asset, _to, _amount);
    }

    /// @dev Authorizes an upgrade to a new implementation.
    /// @dev Only the owner can authorize upgrades.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner { }
}
