// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { IConditionalTokens } from "@ctf-exchange-v2/src/adapters/interfaces/IConditionalTokens.sol";
import { CTFHelpers } from "@ctf-exchange-v2/src/adapters/libraries/CTFHelpers.sol";
import { CollateralToken } from "@ctf-exchange-v2/src/collateral/CollateralToken.sol";
import { Pausable } from "@ctf-exchange-v2/src/collateral/abstract/Pausable.sol";
import { ERC1155TokenReceiver } from "@ctf-exchange-v2/src/exchange/mixins/ERC1155TokenReceiver.sol";

/// @title CtfCollateralAdapter
/// @author Polymarket
/// @notice An adapter for interfacing with ConditionalTokens Markets
///         using the PolymarketCollateralToken
contract CtfCollateralAdapter is Pausable, ERC1155TokenReceiver {
    using SafeTransferLib for address;

    /*--------------------------------------------------------------
                                 STATE
    --------------------------------------------------------------*/

    IConditionalTokens public immutable conditionalTokens;

    address public immutable collateralToken;
    address public immutable usdce;

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    constructor(address _owner, address _admin, address _conditionalTokens, address _collateralToken, address _usdce) {
        conditionalTokens = IConditionalTokens(_conditionalTokens);
        collateralToken = _collateralToken;
        usdce = _usdce;

        _initializeOwner(_owner);
        _grantRoles(_admin, ADMIN_ROLE);

        _usdce.safeApprove(_conditionalTokens, type(uint256).max);
    }

    /*--------------------------------------------------------------
                                EXTERNAL
    --------------------------------------------------------------*/

    /// @notice Splits collateral into conditional token positions
    /// @dev Unnamed params retained for IConditionalTokens interface compatibility
    /// @param _conditionId The condition ID to split on
    /// @param _amount The amount of collateral to split
    function splitPosition(address, bytes32, bytes32 _conditionId, uint256[] calldata, uint256 _amount)
        external
        onlyUnpaused(usdce)
    {
        collateralToken.safeTransferFrom(msg.sender, collateralToken, _amount);
        CollateralToken(collateralToken).unwrap(usdce, address(this), _amount, address(0), "");

        _splitPosition(_conditionId, _amount);

        uint256[] memory positionIds = _getPositionIds(_conditionId);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _amount;
        amounts[1] = _amount;

        conditionalTokens.safeBatchTransferFrom(address(this), msg.sender, positionIds, amounts, "");
    }

    /// @notice Merges conditional token positions back into collateral
    /// @dev Unnamed params retained for IConditionalTokens interface compatibility
    /// @param _conditionId The condition ID to merge on
    /// @param _amount The amount of each position to merge
    function mergePositions(address, bytes32, bytes32 _conditionId, uint256[] calldata, uint256 _amount)
        external
        onlyUnpaused(usdce)
    {
        uint256[] memory positionIds = _getPositionIds(_conditionId);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _amount;
        amounts[1] = _amount;

        conditionalTokens.safeBatchTransferFrom(msg.sender, address(this), positionIds, amounts, "");

        _mergePositions(_conditionId, _amount);

        usdce.safeTransfer(collateralToken, _amount);
        CollateralToken(collateralToken).wrap(usdce, msg.sender, _amount, address(0), "");
    }

    /// @notice Redeems conditional token positions for collateral after resolution
    /// @dev Unnamed params retained for IConditionalTokens interface compatibility
    /// @param _conditionId The condition ID to redeem
    function redeemPositions(address, bytes32, bytes32 _conditionId, uint256[] calldata) external onlyUnpaused(usdce) {
        uint256[] memory positionIds = _getPositionIds(_conditionId);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = conditionalTokens.balanceOf(msg.sender, positionIds[0]);
        amounts[1] = conditionalTokens.balanceOf(msg.sender, positionIds[1]);

        conditionalTokens.safeBatchTransferFrom(msg.sender, address(this), positionIds, amounts, "");

        _redeemPositions(_conditionId, CTFHelpers.partition());

        uint256 amount = usdce.balanceOf(address(this));

        usdce.safeTransfer(collateralToken, amount);
        CollateralToken(collateralToken).wrap(usdce, msg.sender, amount, address(0), "");
    }

    /*--------------------------------------------------------------
                               ONLY ADMIN
    --------------------------------------------------------------*/

    /// @notice Adds a new admin
    /// @param _admin The address of the new admin
    function addAdmin(address _admin) external onlyRoles(ADMIN_ROLE) {
        _grantRoles(_admin, ADMIN_ROLE);
    }

    /// @notice Removes an admin
    /// @param _admin The address of the admin to remove
    function removeAdmin(address _admin) external onlyRoles(ADMIN_ROLE) {
        _removeRoles(_admin, ADMIN_ROLE);
    }

    /*--------------------------------------------------------------
                                INTERNAL
    --------------------------------------------------------------*/

    function _getPositionIds(bytes32 _conditionId) internal view virtual returns (uint256[] memory) {
        return CTFHelpers.positionIds(usdce, _conditionId);
    }

    function _splitPosition(bytes32 _conditionId, uint256 _amount) internal virtual {
        conditionalTokens.splitPosition(usdce, bytes32(0), _conditionId, CTFHelpers.partition(), _amount);
    }

    function _mergePositions(bytes32 _conditionId, uint256 _amount) internal virtual {
        conditionalTokens.mergePositions(usdce, bytes32(0), _conditionId, CTFHelpers.partition(), _amount);
    }

    function _redeemPositions(bytes32 _conditionId, uint256[] memory indexSets) internal virtual {
        conditionalTokens.redeemPositions(usdce, bytes32(0), _conditionId, indexSets);
    }
}
