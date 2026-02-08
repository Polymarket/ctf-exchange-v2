// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Auth } from "./mixins/Auth.sol";
import { Fees } from "./mixins/Fees.sol";
import { Assets } from "./mixins/Assets.sol";
import { Hashing } from "./mixins/Hashing.sol";
import { Trading } from "./mixins/Trading.sol";
import { Pausable } from "./mixins/Pausable.sol";
import { Signatures } from "./mixins/Signatures.sol";
import { UserPausable } from "./mixins/UserPausable.sol";
import { AssetOperations } from "./mixins/AssetOperations.sol";
import { ERC1155TokenReceiver } from "./mixins/ERC1155TokenReceiver.sol";

import { ExchangeInitParams, Order } from "./libraries/Structs.sol";

/// @title CTF Exchange
/// @notice Implements logic for trading CTF assets
/// @author Polymarket
contract CTFExchange is
    Auth,
    Assets,
    ERC1155TokenReceiver,
    Fees,
    Pausable,
    AssetOperations,
    Hashing,
    Signatures,
    UserPausable,
    Trading
{
    constructor(ExchangeInitParams memory params)
        Auth(params.admin)
        Assets(params.collateral, params.ctf, params.outcomeTokenFactory)
        Signatures(params.proxyFactory, params.safeFactory)
        Fees(params.feeReceiver)
    { }

    /*//////////////////////////////////////////////////////////////
                        PAUSE
    //////////////////////////////////////////////////////////////*/

    /// @notice Pause trading on the Exchange
    function pauseTrading() external onlyAdmin {
        _pauseTrading();
    }

    /// @notice Unpause trading on the Exchange
    function unpauseTrading() external onlyAdmin {
        _unpauseTrading();
    }

    /*//////////////////////////////////////////////////////////////
                        TRADING
    //////////////////////////////////////////////////////////////*/

    /// @notice Matches a taker order against a list of maker orders
    /// @param conditionId          - The conditionId of the market being traded
    /// @param takerOrder           - The active order to be matched
    /// @param makerOrders          - The array of maker orders to be matched against the active order
    /// @param takerFillAmount      - The amount to fill on the taker order, always in terms of the maker amount
    /// taker amount
    /// @param makerFillAmounts     - The array of amounts to fill on the maker orders, always in terms of
    /// the maker amount
    /// @param takerFeeAmount       - The fee to be charged to the taker order
    /// @param makerFeeAmounts      - The fee to be charged to the maker orders
    function matchOrders(
        bytes32 conditionId,
        Order memory takerOrder,
        Order[] memory makerOrders,
        uint256 takerFillAmount,
        uint256[] memory makerFillAmounts,
        uint256 takerFeeAmount,
        uint256[] memory makerFeeAmounts
    ) external onlyOperator notPaused {
        _matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, makerFillAmounts, takerFeeAmount, makerFeeAmounts
        );
    }

    /*//////////////////////////////////////////////////////////////
                        CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the user pause block interval
    /// @param _interval - The new user pause block interval
    function setUserPauseBlockInterval(uint256 _interval) external onlyAdmin {
        _setUserPauseBlockInterval(_interval);
    }

    /// @notice Sets a new fee receiver for the Exchange
    /// @param receiver - The new fee receiver address
    function setFeeReceiver(address receiver) external onlyAdmin {
        _setFeeReceiver(receiver);
    }

    /// @notice Sets the maximum fee rate for trades
    /// @param rate - The new max fee rate in basis points
    function setMaxFeeRate(uint256 rate) external onlyAdmin {
        _setMaxFeeRate(rate);
    }
}
