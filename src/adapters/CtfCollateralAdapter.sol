// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { IConditionalTokens } from "src/adapters/interfaces/IConditionalTokens.sol";
import { CTFHelpers } from "src/adapters/libraries/CTFHelpers.sol";
import { CollateralToken } from "src/collateral/CollateralToken.sol";
import { ICollateralTokenCallbacks } from "src/collateral/interfaces/ICollateralTokenCallbacks.sol";
import { ERC1155TokenReceiver } from "src/exchange/mixins/ERC1155TokenReceiver.sol";

/// @title CtfCollateralAdapter
/// @author Polymarket
/// @notice An adapter for interfacing with ConditionalTokens Markets
///         using the PolymarketCollateralToken
contract CtfCollateralAdapter is ERC1155TokenReceiver, ICollateralTokenCallbacks {
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

    constructor(address _conditionalTokens, address _collateralToken, address _usdce) {
        conditionalTokens = IConditionalTokens(_conditionalTokens);
        collateralToken = _collateralToken;
        usdce = _usdce;

        _usdce.safeApprove(_conditionalTokens, type(uint256).max);
    }

    /*--------------------------------------------------------------
                                EXTERNAL
    --------------------------------------------------------------*/

    function splitPosition(address, bytes32, bytes32 _conditionId, uint256[] calldata _partition, uint256 _amount)
        external
    {
        collateralToken.safeTransferFrom(msg.sender, collateralToken, _amount);
        CollateralToken(collateralToken).unwrap(usdce, address(this), _amount, "");

        _splitPosition(_conditionId, _partition, _amount);

        uint256[] memory positionIds = _getPositionIds(_conditionId);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _amount;
        amounts[1] = _amount;

        conditionalTokens.safeBatchTransferFrom(address(this), msg.sender, positionIds, amounts, "");
    }

    function mergePositions(address, bytes32, bytes32 _conditionId, uint256[] calldata _partition, uint256 _amount)
        external
    {
        uint256[] memory positionIds = _getPositionIds(_conditionId);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _amount;
        amounts[1] = _amount;

        conditionalTokens.safeBatchTransferFrom(msg.sender, address(this), positionIds, amounts, "");

        _mergePositions(_conditionId, _partition, _amount);

        usdce.safeTransfer(collateralToken, _amount);
        CollateralToken(collateralToken).wrap(usdce, msg.sender, _amount, "");
    }

    function redeemPositions(address, bytes32, bytes32 _conditionId, uint256[] calldata) external {
        uint256[] memory positionIds = _getPositionIds(_conditionId);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = conditionalTokens.balanceOf(msg.sender, positionIds[0]);
        amounts[1] = conditionalTokens.balanceOf(msg.sender, positionIds[1]);

        conditionalTokens.safeBatchTransferFrom(msg.sender, address(this), positionIds, amounts, "");

        _redeemPositions(_conditionId, CTFHelpers.partition());

        uint256 amount = usdce.balanceOf(address(this));

        usdce.safeTransfer(collateralToken, amount);
        CollateralToken(collateralToken).wrap(usdce, msg.sender, amount, "");
    }

    /*--------------------------------------------------------------
                                INTERNAL
    --------------------------------------------------------------*/

    function _getPositionIds(bytes32 _conditionId) internal view virtual returns (uint256[] memory) {
        return CTFHelpers.positionIds(usdce, _conditionId);
    }

    function _splitPosition(bytes32 _conditionId, uint256[] calldata _partition, uint256 _amount) internal virtual {
        conditionalTokens.splitPosition(usdce, bytes32(0), _conditionId, _partition, _amount);
    }

    function _mergePositions(bytes32 _conditionId, uint256[] calldata _partition, uint256 _amount) internal virtual {
        conditionalTokens.mergePositions(usdce, bytes32(0), _conditionId, _partition, _amount);
    }

    function _redeemPositions(bytes32 _conditionId, uint256[] memory indexSets) internal virtual {
        conditionalTokens.redeemPositions(usdce, bytes32(0), _conditionId, indexSets);
    }

    /*--------------------------------------------------------------
                               CALLBACKS
    --------------------------------------------------------------*/

    function wrapCallback(address, address, uint256, bytes calldata) external { }
    function unwrapCallback(address, address, uint256, bytes calldata) external { }
}
