// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

import { SafeTransferLib } from "@solady/src/utils/SafeTransferLib.sol";

import { CTFHelpers } from "@ctf-exchange-v2/src/adapters/libraries/CTFHelpers.sol";
import { INegRiskAdapter } from "@ctf-exchange-v2/src/adapters/interfaces/INegRiskAdapter.sol";
import { CollateralToken } from "@ctf-exchange-v2/src/collateral/CollateralToken.sol";

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

    /// @notice The legacy NegRisk adapter contract address.
    address public immutable NEG_RISK_ADAPTER;

    /// @notice The wrapped collateral token from the legacy adapter.
    address public immutable WRAPPED_COLLATERAL;

    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    /// @notice Deploys the NegRisk CTF collateral adapter.
    /// @param _owner The contract owner.
    /// @param _admin The initial admin address.
    /// @param _conditionalTokens The legacy CTF contract address.
    /// @param _collateralToken The collateral token (PMCT) address.
    /// @param _usdce The USDC.e token address.
    /// @param _negRiskAdapter The legacy NegRisk adapter address.
    constructor(
        address _owner,
        address _admin,
        address _conditionalTokens,
        address _collateralToken,
        address _usdce,
        address _negRiskAdapter
    ) CtfCollateralAdapter(_owner, _admin, _conditionalTokens, _collateralToken, _usdce) {
        NEG_RISK_ADAPTER = _negRiskAdapter;
        WRAPPED_COLLATERAL = INegRiskAdapter(_negRiskAdapter).wcol();

        _usdce.safeApprove(_negRiskAdapter, type(uint256).max);
        CONDITIONAL_TOKENS.setApprovalForAll(_negRiskAdapter, true);
    }

    /*--------------------------------------------------------------
                                EXTERNAL
    --------------------------------------------------------------*/

    /// @notice Converts NO positions into YES positions via the NegRiskAdapter
    /// @param _marketId The neg risk market ID
    /// @param _indexSet Bitmask of question indices whose NO tokens to convert
    /// @param _amount The amount of each NO position to convert
    function convertPositions(bytes32 _marketId, uint256 _indexSet, uint256 _amount) external onlyUnpaused(USDCE) {
        INegRiskAdapter adapter = INegRiskAdapter(NEG_RISK_ADAPTER);
        uint256 questionCount = adapter.getQuestionCount(_marketId);
        uint256 feeBips = adapter.getFeeBips(_marketId);

        // Pull NO tokens from caller
        {
            (uint256[] memory ids, uint256[] memory amounts) =
                _buildPositionArrays(adapter, _marketId, _indexSet, questionCount, false, _amount);
            CONDITIONAL_TOKENS.safeBatchTransferFrom(msg.sender, address(this), ids, amounts, "");
        }

        // Convert positions via NegRiskAdapter
        adapter.convertPositions(_marketId, _indexSet, _amount);

        // Send YES tokens to caller
        {
            uint256 amountOut = _amount - (_amount * feeBips / 10_000);
            (uint256[] memory ids, uint256[] memory amounts) =
                _buildPositionArrays(adapter, _marketId, _indexSet, questionCount, true, amountOut);
            CONDITIONAL_TOKENS.safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
        }

        // Wrap any received USDC.e into CollateralToken
        uint256 usdceAmount = USDCE.balanceOf(address(this));
        if (usdceAmount > 0) {
            USDCE.safeTransfer(COLLATERAL_TOKEN, usdceAmount);
            // forgefmt: disable-next-item
            CollateralToken(COLLATERAL_TOKEN).wrap({
                _asset: USDCE,
                _to: msg.sender,
                _amount: usdceAmount,
                _callbackReceiver: address(0),
                _data: ""
            });
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
            // forge-lint: disable-next-line(incorrect-shift)
            bool inSet = _indexSet & (1 << i) != 0;
            if (inSet != _yesPositions) ++count;
        }

        ids = new uint256[](count);
        amounts = new uint256[](count);
        uint256 idx;

        for (uint256 i; i < _questionCount; ++i) {
            // forge-lint: disable-next-line(incorrect-shift)
            bool inSet = _indexSet & (1 << i) != 0;
            if (inSet != _yesPositions) {
                bytes32 questionId = bytes32(uint256(_marketId) | i);
                ids[idx] = _adapter.getPositionId(questionId, _yesPositions);
                amounts[idx] = _amount;
                ++idx;
            }
        }
    }

    /// @dev Returns position IDs using wrapped collateral.
    function _getPositionIds(bytes32 _conditionId) internal view virtual override returns (uint256[] memory) {
        return CTFHelpers.positionIds(WRAPPED_COLLATERAL, _conditionId);
    }

    /// @dev Splits via the NegRisk adapter.
    function _splitPosition(bytes32 _conditionId, uint256 _amount) internal virtual override {
        INegRiskAdapter(NEG_RISK_ADAPTER).splitPosition(_conditionId, _amount);
    }

    /// @dev Merges via the NegRisk adapter.
    function _mergePositions(bytes32 _conditionId, uint256 _amount) internal virtual override {
        INegRiskAdapter(NEG_RISK_ADAPTER).mergePositions(_conditionId, _amount);
    }

    /// @dev Redeems via the NegRisk adapter using current balances.
    function _redeemPositions(bytes32 _conditionId, uint256[] memory) internal virtual override {
        uint256[] memory positionIds = _getPositionIds(_conditionId);
        uint256[] memory amounts = new uint256[](2);

        amounts[0] = CONDITIONAL_TOKENS.balanceOf(address(this), positionIds[0]);
        amounts[1] = CONDITIONAL_TOKENS.balanceOf(address(this), positionIds[1]);

        INegRiskAdapter(NEG_RISK_ADAPTER).redeemPositions(_conditionId, amounts);
    }
}
