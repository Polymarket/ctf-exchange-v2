// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import { SafeTransferLib } from "lib/solady/src/utils/SafeTransferLib.sol";

import { CTFHelpers } from "src/adapters/libraries/CTFHelpers.sol";
import { INegRiskAdapter } from "src/adapters/interfaces/INegRiskAdapter.sol";
import { CollateralToken } from "src/collateral/CollateralToken.sol";

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

    constructor(
        address _owner,
        address _admin,
        address _conditionalTokens,
        address _collateralToken,
        address _usdce,
        address _negRiskAdapter
    ) CtfCollateralAdapter(_owner, _admin, _conditionalTokens, _collateralToken, _usdce) {
        negRiskAdapter = _negRiskAdapter;
        wrappedCollateral = INegRiskAdapter(_negRiskAdapter).wcol();

        _usdce.safeApprove(_negRiskAdapter, type(uint256).max);
        conditionalTokens.setApprovalForAll(_negRiskAdapter, true);
    }

    /*--------------------------------------------------------------
                                EXTERNAL
    --------------------------------------------------------------*/

    /// @notice Converts NO positions into YES positions via the NegRiskAdapter
    /// @param _marketId The neg risk market ID
    /// @param _indexSet Bitmask of question indices whose NO tokens to convert
    /// @param _amount The amount of each NO position to convert
    function convertPositions(bytes32 _marketId, uint256 _indexSet, uint256 _amount) external onlyUnpaused(usdce) {
        INegRiskAdapter adapter = INegRiskAdapter(negRiskAdapter);
        uint256 questionCount = adapter.getQuestionCount(_marketId);
        uint256 feeBips = adapter.getFeeBips(_marketId);

        // Pull NO tokens from caller
        {
            (uint256[] memory ids, uint256[] memory amounts) =
                _buildPositionArrays(adapter, _marketId, _indexSet, questionCount, false, _amount);
            conditionalTokens.safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
        }

        // Convert positions via NegRiskAdapter
        adapter.convertPositions(_marketId, _indexSet, _amount);

        // Send YES tokens to caller
        {
            uint256 amountOut = _amount - (_amount * feeBips / 10_000);
            (uint256[] memory ids, uint256[] memory amounts) =
                _buildPositionArrays(adapter, _marketId, _indexSet, questionCount, true, amountOut);
            conditionalTokens.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
        }

        // Wrap any received USDC.e into CollateralToken
        uint256 usdceAmount = usdce.balanceOf(address(this));
        if (usdceAmount > 0) {
            usdce.safeTransfer(collateralToken, usdceAmount);
            CollateralToken(collateralToken).wrap(usdce, msg.sender, usdceAmount, address(0), "");
        }
    }

    /*--------------------------------------------------------------
                                INTERNAL
    --------------------------------------------------------------*/

    /// @dev Builds arrays of position IDs and amounts for either the NO side (inSet=false) or YES side (inSet=true).
    ///      When inSet=false, selects questions whose bit IS set in _indexSet (NO positions).
    ///      When inSet=true, selects questions whose bit is NOT set in _indexSet (YES positions).
    function _buildPositionArrays(
        INegRiskAdapter _adapter,
        bytes32 _marketId,
        uint256 _indexSet,
        uint256 _questionCount,
        bool _yesPositions,
        uint256 _amount
    ) internal view returns (uint256[] memory ids, uint256[] memory amounts) {
        uint256 count;
        for (uint256 i; i < _questionCount; ++i) {
            bool inSet = _indexSet & (1 << i) != 0;
            if (inSet != _yesPositions) ++count;
        }

        ids = new uint256[](count);
        amounts = new uint256[](count);
        uint256 idx;

        for (uint256 i; i < _questionCount; ++i) {
            bool inSet = _indexSet & (1 << i) != 0;
            if (inSet != _yesPositions) {
                bytes32 questionId = bytes32(uint256(_marketId) | i);
                ids[idx] = _adapter.getPositionId(questionId, _yesPositions);
                amounts[idx] = _amount;
                ++idx;
            }
        }
    }

    function _getPositionIds(bytes32 _conditionId) internal view virtual override returns (uint256[] memory) {
        return CTFHelpers.positionIds(wrappedCollateral, _conditionId);
    }

    function _splitPosition(bytes32 _conditionId, uint256 _amount) internal virtual override {
        INegRiskAdapter(negRiskAdapter).splitPosition(_conditionId, _amount);
    }

    function _mergePositions(bytes32 _conditionId, uint256 _amount) internal virtual override {
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
