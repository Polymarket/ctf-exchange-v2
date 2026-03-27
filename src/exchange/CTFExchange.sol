// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.34;

import { Auth } from "./mixins/Auth.sol";
import { Fees } from "./mixins/Fees.sol";
import { Assets } from "./mixins/Assets.sol";
import { Trading } from "./mixins/Trading.sol";
import { Pausable } from "./mixins/Pausable.sol";
import { Signatures } from "./mixins/Signatures.sol";
import { ERC1155TokenReceiver } from "./mixins/ERC1155TokenReceiver.sol";

import { ExchangeInitParams, Order } from "./libraries/Structs.sol";

//  ____   ___  _  __   ____  __    _    ____  _  _______ _____
// |  _ \ / _ \| | \ \ / /  \/  |  / \  |  _ \| |/ / ____|_   _|
// | |_) | | | | |  \ V /| |\/| | / _ \ | |_) | ' /|  _|   | |
// |  __/| |_| | |___| | | |  | |/ ___ \|  _ <| . \| |___  | |
// |_|    \___/|_____|_| |_|  |_/_/   \_\_| \_\_|\_\_____| |_|

/// @title CTF Exchange
/// @notice Implements logic for trading CTF assets
/// @author Polymarket
contract CTFExchange is Auth, ERC1155TokenReceiver, Pausable, Trading {
    /*--------------------------------------------------------------
                              CONSTRUCTOR
    --------------------------------------------------------------*/

    constructor(ExchangeInitParams memory params)
        Auth(params.admin)
        Assets(params.collateral, params.ctf, params.ctfCollateral, params.outcomeTokenFactory)
        Signatures(params.proxyFactory, params.safeFactory)
        Fees(params.feeReceiver)
    { }

    /*--------------------------------------------------------------
                             ONLY OPERATOR
    --------------------------------------------------------------*/

    /// @notice Matches a taker order against a list of maker orders
    /// @param conditionId          - The conditionId of the market being traded
    /// @param takerOrder           - The active order to be matched
    /// @param makerOrders          - The array of maker orders to be matched against the active order
    /// @param takerFillAmount      - The amount to fill on the taker order, always in terms of the maker amount
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
        uint256 makerLength = makerOrders.length;
        require(makerLength > 0, NoMakerOrders());
        require(
            makerLength == makerFillAmounts.length && makerLength == makerFeeAmounts.length, MismatchedArrayLengths()
        );

        _matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, makerFillAmounts, takerFeeAmount, makerFeeAmounts
        );
    }

    /// @notice Entrypoint to set an order as preapproved
    /// @param order - The order to be set as preapproved
    function preapproveOrder(Order memory order) external onlyOperator {
        bytes32 orderHash = hashOrder(order);

        _preapproveOrder(orderHash, order);
    }

    /// @notice Entrypoint to invalidate a preapproval
    /// @param orderHash - The hash of the order to invalidate
    function invalidatePreapprovedOrder(bytes32 orderHash) external onlyOperator {
        _invalidatePreapprovedOrder(orderHash);
    }

    /*--------------------------------------------------------------
                               ONLY ADMIN
    --------------------------------------------------------------*/

    /// @notice Pause trading on the Exchange
    function pauseTrading() external onlyAdmin {
        _pauseTrading();
    }

    /// @notice Unpause trading on the Exchange
    function unpauseTrading() external onlyAdmin {
        _unpauseTrading();
    }

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
