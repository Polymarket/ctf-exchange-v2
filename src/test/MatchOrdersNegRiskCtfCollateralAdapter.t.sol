// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { Order, Side, ExchangeInitParams } from "@ctf-exchange-v2/src/exchange/libraries/Structs.sol";
import { ERC1155 } from "@solady/src/tokens/ERC1155.sol";

import { CTFExchange } from "@ctf-exchange-v2/src/exchange/CTFExchange.sol";

import { Collateral, CollateralSetup } from "@ctf-exchange-v2/src/test/dev/CollateralSetup.sol";
import { USDCe } from "@ctf-exchange-v2/src/test/dev/mocks/USDCe.sol";
import { Deployer } from "@ctf-exchange-v2/src/test/dev/util/Deployer.sol";
import { INegRiskAdapter } from "@ctf-exchange-v2/src/adapters/interfaces/INegRiskAdapter.sol";
import { CTFHelpers } from "@ctf-exchange-v2/src/adapters/libraries/CTFHelpers.sol";
import { NegRiskCtfCollateralAdapter } from "@ctf-exchange-v2/src/adapters/NegRiskCtfCollateralAdapter.sol";

contract MatchOrdersNegRiskCtfCollateralAdapterTest is BaseExchangeTest {
    NegRiskCtfCollateralAdapter public adapter;

    Collateral collateral;
    USDCe usdce;

    INegRiskAdapter negRiskAdapter;
    address wrappedCol;

    function setUp() public override {
        super.setUp();

        // 1. Deploy CollateralToken system
        collateral = CollateralSetup._deploy(admin);
        usdce = collateral.usdce;

        // 2. Deploy NegRiskAdapter reusing the existing CTF from super.setUp()
        address vault = vm.createWallet("nrVault").addr;
        negRiskAdapter = INegRiskAdapter(Deployer.deployNegRiskAdapter(address(ctf), address(usdce), vault));
        negRiskAdapter.addAdmin(admin);
        negRiskAdapter.renounceAdmin();
        wrappedCol = negRiskAdapter.wcol();

        // 3. Deploy real NegRiskCtfCollateralAdapter
        adapter = new NegRiskCtfCollateralAdapter(
            admin, admin, address(ctf), address(collateral.token), address(usdce), address(negRiskAdapter)
        );
        vm.label(address(adapter), "NegRiskCtfCollateralAdapter");

        // 4. Grant ROLE_1 (1 << 1) on CollateralToken to the adapter
        vm.prank(admin);
        collateral.token.addWrapper(address(adapter));

        // 5. Prepare NegRisk market + question
        bytes memory data = new bytes(0);
        vm.startPrank(admin);
        bytes32 marketId = negRiskAdapter.prepareMarket(0, data);
        bytes32 questionId = negRiskAdapter.prepareQuestion(marketId, data);
        conditionId = negRiskAdapter.getConditionId(questionId);
        vm.stopPrank();

        // 6. Recompute yes/no using wrappedCollateral
        uint256[] memory positionIds = CTFHelpers.positionIds(wrappedCol, conditionId);
        yes = positionIds[0];
        no = positionIds[1];

        // 7. Create new CTFExchange with collateral: collateralToken, outcomeTokenFactory: adapter
        vm.startPrank(admin);
        ExchangeInitParams memory p = ExchangeInitParams({
            admin: admin,
            collateral: address(collateral.token),
            ctf: address(ctf),
            ctfCollateral: wrappedCol,
            outcomeTokenFactory: address(adapter),
            proxyFactory: proxyFactory,
            safeFactory: safeFactory,
            feeReceiver: feeReceiver
        });

        exchange = new CTFExchange(p);
        exchange.addOperator(bob);
        exchange.addOperator(carla);
        vm.stopPrank();
    }

    // ---------------------------------------------------------------
    //  Helpers
    // ---------------------------------------------------------------

    function _dealCollateralAndApprove(address to, address spender, uint256 amount) internal {
        usdce.mint(to, amount);
        vm.startPrank(to);
        usdce.approve(address(collateral.onramp), amount);
        collateral.onramp.wrap(address(usdce), to, amount);
        collateral.token.approve(spender, amount);
        vm.stopPrank();
    }

    function _dealOutcomeTokensAndApprove(address to, address spender, uint256 tokenId, uint256 amount) internal {
        usdce.mint(admin, amount);

        vm.startPrank(admin);
        usdce.approve(address(negRiskAdapter), amount);
        negRiskAdapter.splitPosition(conditionId, amount);
        ERC1155(address(ctf)).safeTransferFrom(admin, to, tokenId, amount, "");
        vm.stopPrank();

        vm.prank(to);
        ERC1155(address(ctf)).setApprovalForAll(spender, true);
    }

    function assertPMCTBalance(address _who, uint256 _amount) public view {
        assertEq(collateral.token.balanceOf(_who), _amount);
    }

    // ---------------------------------------------------------------
    //  Tests
    // ---------------------------------------------------------------

    function test_MatchOrdersNegRiskCtfCollateralAdapter_Mint() public {
        _dealCollateralAndApprove(bob, address(exchange), 50_000_000);
        _dealCollateralAndApprove(carla, address(exchange), 50_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertPMCTBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        assertPMCTBalance(carla, 0);
        assertCTFBalance(carla, no, 100_000_000);
    }

    function test_MatchOrdersNegRiskCtfCollateralAdapter_Mint_Fees() public {
        uint256 takerFeeAmount = 2_500_000;
        uint256 makerFeeAmount = 100_000;

        _dealCollateralAndApprove(bob, address(exchange), 50_000_000 + takerFeeAmount);
        _dealCollateralAndApprove(carla, address(exchange), 50_000_000 + makerFeeAmount);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertPMCTBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        assertPMCTBalance(carla, 0);
        assertCTFBalance(carla, no, 100_000_000);
        assertPMCTBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrdersNegRiskCtfCollateralAdapter_Complementary() public {
        _dealCollateralAndApprove(bob, address(exchange), 50_000_000);
        _dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertPMCTBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        assertCTFBalance(carla, yes, 0);
        assertPMCTBalance(carla, 50_000_000);
    }

    function test_MatchOrdersNegRiskCtfCollateralAdapter_Complementary_Fees() public {
        uint256 takerFeeAmount = 2_500_000;
        uint256 makerFeeAmount = 100_000;

        _dealCollateralAndApprove(bob, address(exchange), 50_000_000 + takerFeeAmount);
        _dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertPMCTBalance(bob, 0);
        assertCTFBalance(bob, yes, 100_000_000);
        assertCTFBalance(carla, yes, 0);
        assertPMCTBalance(carla, 50_000_000 - makerFeeAmount);
        assertPMCTBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrdersNegRiskCtfCollateralAdapter_Merge() public {
        _dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        _dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertCTFBalance(bob, yes, 0);
        assertPMCTBalance(bob, 50_000_000);
        assertCTFBalance(carla, no, 0);
        assertPMCTBalance(carla, 50_000_000);
    }

    function test_MatchOrdersNegRiskCtfCollateralAdapter_Merge_Fees() public {
        uint256 takerFeeAmount = 1_000_000;
        uint256 makerFeeAmount = 500_000;

        _dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        _dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = makerFeeAmount;

        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );

        assertCTFBalance(bob, yes, 0);
        assertPMCTBalance(bob, 50_000_000 - takerFeeAmount);
        assertCTFBalance(carla, no, 0);
        assertPMCTBalance(carla, 50_000_000 - makerFeeAmount);
        assertPMCTBalance(feeReceiver, takerFeeAmount + makerFeeAmount);
    }

    function test_MatchOrdersNegRiskCtfCollateralAdapter_Merge_Reverts_WhenAdapterNotApproved() public {
        vm.prank(address(exchange));
        ERC1155(address(ctf)).setApprovalForAll(address(adapter), false);

        _dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        _dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);

        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);
        Order memory makerOrder = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 100_000_000;

        uint256 takerFillAmount = 100_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.expectRevert();
        vm.prank(admin);
        exchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );
    }

    function test_MatchOrdersNegRiskCtfCollateralAdapter_Mint_Reverts_WhenAdapterUsdceMismatch() public {
        USDCe otherUsdce = new USDCe();

        NegRiskCtfCollateralAdapter badAdapter = new NegRiskCtfCollateralAdapter(
            admin, admin, address(ctf), address(collateral.token), address(otherUsdce), address(negRiskAdapter)
        );

        vm.prank(admin);
        collateral.token.addWrapper(address(badAdapter));

        vm.startPrank(admin);
        ExchangeInitParams memory p = ExchangeInitParams({
            admin: admin,
            collateral: address(collateral.token),
            ctf: address(ctf),
            ctfCollateral: wrappedCol,
            outcomeTokenFactory: address(badAdapter),
            proxyFactory: proxyFactory,
            safeFactory: safeFactory,
            feeReceiver: feeReceiver
        });

        CTFExchange badExchange = new CTFExchange(p);
        badExchange.addOperator(bob);
        badExchange.addOperator(carla);
        vm.stopPrank();

        _dealCollateralAndApprove(bob, address(badExchange), 50_000_000);
        _dealCollateralAndApprove(carla, address(badExchange), 50_000_000);

        Order memory takerOrder = _createOrder(bob, yes, 50_000_000, 100_000_000, Side.BUY);
        takerOrder.signature = _signMessage(bobPK, badExchange.hashOrder(takerOrder));
        Order memory makerOrder = _createOrder(carla, no, 50_000_000, 100_000_000, Side.BUY);
        makerOrder.signature = _signMessage(carlaPK, badExchange.hashOrder(makerOrder));

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000;

        uint256 takerFillAmount = 50_000_000;
        uint256 takerFeeAmount = 0;
        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        vm.expectRevert();
        vm.prank(admin);
        badExchange.matchOrders(
            conditionId, takerOrder, makerOrders, takerFillAmount, fillAmounts, takerFeeAmount, makerFeeAmounts
        );
    }
}
