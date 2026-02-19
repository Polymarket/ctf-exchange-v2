// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { CTFHelpers } from "src/adapters/libraries/CTFHelpers.sol";
import { INegRiskAdapter } from "src/adapters/interfaces/INegRiskAdapter.sol";

import { CtfCollateralAdapter } from "./CtfCollateralAdapter.sol";

/// @title NegRiskCtfCollateralAdapter
/// @author Polymarket
/// @notice An adapter for interfacing with NegRisk-ConditionalTokens Markets
///         using the PolymarketCollateralToken
contract NegRiskCtfCollateralAdapter is CtfCollateralAdapter {
    using SafeTransferLib for address;

    /*--------------------------------------------------------------
                                 STATE
    --------------------------------------------------------------*/

    address public immutable negRiskAdapter;
    address public immutable wrappedCollateral;

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    constructor(address _conditionalTokens, address _collateralToken, address _usdce, address _negRiskAdapter)
        CtfCollateralAdapter(_conditionalTokens, _collateralToken, _usdce)
    {
        negRiskAdapter = _negRiskAdapter;
        wrappedCollateral = INegRiskAdapter(_negRiskAdapter).wcol();

        _usdce.safeApprove(_negRiskAdapter, type(uint256).max);
        conditionalTokens.setApprovalForAll(_negRiskAdapter, true);
    }

    /*--------------------------------------------------------------
                                INTERNAL
    --------------------------------------------------------------*/

    function _getPositionIds(bytes32 _conditionId) internal view virtual override returns (uint256[] memory) {
        return CTFHelpers.positionIds(wrappedCollateral, _conditionId);
    }

    function _splitPosition(bytes32 _conditionId, uint256[] calldata, uint256 _amount) internal virtual override {
        INegRiskAdapter(negRiskAdapter).splitPosition(_conditionId, _amount);
    }

    function _mergePositions(bytes32 _conditionId, uint256[] calldata _partition, uint256 _amount)
        internal
        virtual
        override
    {
        INegRiskAdapter(negRiskAdapter).mergePositions(_conditionId, _amount);
    }

    function _redeemPositions(bytes32 _conditionId, uint256[] memory) internal virtual override {
        uint256[] memory positionIds = _getPositionIds(_conditionId);
        uint256[] memory amounts = new uint256[](2);

        amounts[0] = conditionalTokens.balanceOf(address(this), positionIds[0]);
        amounts[1] = conditionalTokens.balanceOf(address(this), positionIds[1]);

        INegRiskAdapter(negRiskAdapter).redeemPositions(_conditionId, amounts);
    }
}
