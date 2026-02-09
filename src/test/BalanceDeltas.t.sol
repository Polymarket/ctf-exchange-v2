// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import { BaseExchangeTest } from "./BaseExchangeTest.sol";
import { Order, Side } from "src/exchange/libraries/Structs.sol";

/// @title Balance Delta Tests
/// @notice Comprehensive tests verifying exact token/collateral amounts for all match types
/// @dev These tests verify correctness from first principles, not implementation details
contract BalanceDeltasTest is BaseExchangeTest {
    // Additional test accounts
    uint256 internal davePK = 0xDA7E;
    uint256 internal evePK = 0xE7E;
    address public dave;
    address public eve;

    function setUp() public override {
        super.setUp();

        // Add dave and eve as additional traders
        dave = vm.addr(davePK);
        eve = vm.addr(evePK);
        vm.label(dave, "dave");
        vm.label(eve, "eve");

        // Add them as operators
        vm.startPrank(admin);
        exchange.addOperator(dave);
        exchange.addOperator(eve);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    MULTI-MAKER COMPLEMENTARY (TAKER BUY)
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Taker BUY matched against multiple Maker SELLs
    /// @dev Verifies each party receives exact expected amounts
    ///
    /// Setup:
    ///   - Bob (taker): BUY 300 YES for 150 USDC (price: 0.50)
    ///   - Carla (maker1): SELL 100 YES for 50 USDC (price: 0.50)
    ///   - Dave (maker2): SELL 200 YES for 100 USDC (price: 0.50)
    ///
    /// Expected:
    ///   - Bob: 150 USDC -> 0, 0 YES -> 300 YES
    ///   - Carla: 0 USDC -> 50, 100 YES -> 0
    ///   - Dave: 0 USDC -> 100, 200 YES -> 0
    ///   - Exchange: holds 0 of everything
    function test_MultiMaker_Complementary_TakerBuy() public {
        // Setup balances
        dealUsdcAndApprove(bob, address(exchange), 150_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);
        dealOutcomeTokensAndApprove(dave, address(exchange), yes, 200_000_000);

        // Create orders
        // Taker: BUY 300 YES for 150 USDC
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 150_000_000, 300_000_000, Side.BUY);

        // Maker1: SELL 100 YES for 50 USDC
        Order memory maker1Order = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);

        // Maker2: SELL 200 YES for 100 USDC
        Order memory maker2Order = _createAndSignOrderWithSalt(davePK, yes, 200_000_000, 100_000_000, Side.SELL, 2);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = maker1Order;
        makerOrders[1] = maker2Order;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 100_000_000; // Fill maker1 fully
        fillAmounts[1] = 200_000_000; // Fill maker2 fully

        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 0;
        makerFeeAmounts[1] = 0;

        // Execute match
        vm.prank(admin);
        exchange.matchOrders(
            conditionId,
            takerOrder,
            makerOrders,
            150_000_000, // takerFillAmount
            fillAmounts,
            0, // takerFeeAmount
            makerFeeAmounts
        );

        // Verify Bob (taker): spent 150 USDC, received 300 YES
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 300_000_000);

        // Verify Carla (maker1): spent 100 YES, received 50 USDC
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 50_000_000);

        // Verify Dave (maker2): spent 200 YES, received 100 USDC
        assertCTFBalance(dave, yes, 0);
        assertCollateralBalance(dave, 100_000_000);

        // Verify exchange holds nothing
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
        assertCTFBalance(address(exchange), no, 0);
    }

    /*//////////////////////////////////////////////////////////////
                    MULTI-MAKER COMPLEMENTARY (TAKER SELL)
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Taker SELL matched against multiple Maker BUYs
    /// @dev Verifies each party receives exact expected amounts
    ///
    /// Setup:
    ///   - Bob (taker): SELL 300 YES for 150 USDC (price: 0.50)
    ///   - Carla (maker1): BUY 100 YES for 50 USDC (price: 0.50)
    ///   - Dave (maker2): BUY 200 YES for 100 USDC (price: 0.50)
    ///
    /// Expected:
    ///   - Bob: 0 USDC -> 150, 300 YES -> 0
    ///   - Carla: 50 USDC -> 0, 0 YES -> 100
    ///   - Dave: 100 USDC -> 0, 0 YES -> 200
    ///   - Exchange: holds 0 of everything
    function test_MultiMaker_Complementary_TakerSell() public {
        // Setup balances
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 300_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);
        dealUsdcAndApprove(dave, address(exchange), 100_000_000);

        // Create orders
        // Taker: SELL 300 YES for 150 USDC
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 300_000_000, 150_000_000, Side.SELL);

        // Maker1: BUY 100 YES for 50 USDC
        Order memory maker1Order = _createAndSignOrder(carlaPK, yes, 50_000_000, 100_000_000, Side.BUY);

        // Maker2: BUY 200 YES for 100 USDC
        Order memory maker2Order = _createAndSignOrderWithSalt(davePK, yes, 100_000_000, 200_000_000, Side.BUY, 2);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = maker1Order;
        makerOrders[1] = maker2Order;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 50_000_000; // Fill maker1 fully (50 USDC)
        fillAmounts[1] = 100_000_000; // Fill maker2 fully (100 USDC)

        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 0;
        makerFeeAmounts[1] = 0;

        // Execute match
        vm.prank(admin);
        exchange.matchOrders(
            conditionId,
            takerOrder,
            makerOrders,
            300_000_000, // takerFillAmount (300 YES)
            fillAmounts,
            0, // takerFeeAmount
            makerFeeAmounts
        );

        // Verify Bob (taker): spent 300 YES, received 150 USDC
        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 150_000_000);

        // Verify Carla (maker1): spent 50 USDC, received 100 YES
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, yes, 100_000_000);

        // Verify Dave (maker2): spent 100 USDC, received 200 YES
        assertCollateralBalance(dave, 0);
        assertCTFBalance(dave, yes, 200_000_000);

        // Verify exchange holds nothing
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
        assertCTFBalance(address(exchange), no, 0);
    }

    /*//////////////////////////////////////////////////////////////
                            MULTI-MAKER MINT
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Taker BUY YES matched against multiple Maker BUY NOs (MINT)
    /// @dev Combined collateral mints outcome tokens via CTF splitPosition
    ///
    /// Setup:
    ///   - Bob (taker): BUY 200 YES for 100 USDC (price: 0.50)
    ///   - Carla (maker1): BUY 100 NO for 50 USDC (price: 0.50)
    ///   - Dave (maker2): BUY 100 NO for 50 USDC (price: 0.50)
    ///
    /// Mechanics: 100 + 50 + 50 = 200 USDC mints 200 YES + 200 NO
    ///
    /// Expected:
    ///   - Bob: 100 USDC -> 0, 0 YES -> 200 YES
    ///   - Carla: 50 USDC -> 0, 0 NO -> 100 NO
    ///   - Dave: 50 USDC -> 0, 0 NO -> 100 NO
    ///   - Exchange: holds 0 of everything
    function test_MultiMaker_Mint() public {
        // Setup balances
        dealUsdcAndApprove(bob, address(exchange), 100_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);
        dealUsdcAndApprove(dave, address(exchange), 50_000_000);

        // Create orders
        // Taker: BUY 200 YES for 100 USDC
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 200_000_000, Side.BUY);

        // Maker1: BUY 100 NO for 50 USDC
        Order memory maker1Order = _createAndSignOrder(carlaPK, no, 50_000_000, 100_000_000, Side.BUY);

        // Maker2: BUY 100 NO for 50 USDC
        Order memory maker2Order = _createAndSignOrderWithSalt(davePK, no, 50_000_000, 100_000_000, Side.BUY, 2);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = maker1Order;
        makerOrders[1] = maker2Order;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 50_000_000; // Fill maker1 fully (50 USDC)
        fillAmounts[1] = 50_000_000; // Fill maker2 fully (50 USDC)

        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 0;
        makerFeeAmounts[1] = 0;

        // Execute match
        vm.prank(admin);
        exchange.matchOrders(
            conditionId,
            takerOrder,
            makerOrders,
            100_000_000, // takerFillAmount (100 USDC)
            fillAmounts,
            0, // takerFeeAmount
            makerFeeAmounts
        );

        // Verify Bob (taker): spent 100 USDC, received 200 YES
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 200_000_000);
        assertCTFBalance(bob, no, 0);

        // Verify Carla (maker1): spent 50 USDC, received 100 NO
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, yes, 0);
        assertCTFBalance(carla, no, 100_000_000);

        // Verify Dave (maker2): spent 50 USDC, received 100 NO
        assertCollateralBalance(dave, 0);
        assertCTFBalance(dave, yes, 0);
        assertCTFBalance(dave, no, 100_000_000);

        // Verify exchange holds nothing
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
        assertCTFBalance(address(exchange), no, 0);
    }

    /*//////////////////////////////////////////////////////////////
                            MULTI-MAKER MERGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Taker SELL YES matched against multiple Maker SELL NOs (MERGE)
    /// @dev Combined outcome tokens merge back to collateral via CTF mergePositions
    ///
    /// Setup:
    ///   - Bob (taker): SELL 200 YES for 100 USDC (price: 0.50)
    ///   - Carla (maker1): SELL 100 NO for 50 USDC (price: 0.50)
    ///   - Dave (maker2): SELL 100 NO for 50 USDC (price: 0.50)
    ///
    /// Mechanics: 200 YES + 200 NO merge into 200 USDC
    ///
    /// Expected:
    ///   - Bob: 0 USDC -> 100, 200 YES -> 0
    ///   - Carla: 0 USDC -> 50, 100 NO -> 0
    ///   - Dave: 0 USDC -> 50, 100 NO -> 0
    ///   - Exchange: holds 0 of everything
    function test_MultiMaker_Merge() public {
        // Setup balances
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 200_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);
        dealOutcomeTokensAndApprove(dave, address(exchange), no, 100_000_000);

        // Create orders
        // Taker: SELL 200 YES for 100 USDC
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 200_000_000, 100_000_000, Side.SELL);

        // Maker1: SELL 100 NO for 50 USDC
        Order memory maker1Order = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);

        // Maker2: SELL 100 NO for 50 USDC
        Order memory maker2Order = _createAndSignOrderWithSalt(davePK, no, 100_000_000, 50_000_000, Side.SELL, 2);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = maker1Order;
        makerOrders[1] = maker2Order;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 100_000_000; // Fill maker1 fully (100 NO)
        fillAmounts[1] = 100_000_000; // Fill maker2 fully (100 NO)

        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 0;
        makerFeeAmounts[1] = 0;

        // Execute match
        vm.prank(admin);
        exchange.matchOrders(
            conditionId,
            takerOrder,
            makerOrders,
            200_000_000, // takerFillAmount (200 YES)
            fillAmounts,
            0, // takerFeeAmount
            makerFeeAmounts
        );

        // Verify Bob (taker): spent 200 YES, received 100 USDC
        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 100_000_000);

        // Verify Carla (maker1): spent 100 NO, received 50 USDC
        assertCTFBalance(carla, no, 0);
        assertCollateralBalance(carla, 50_000_000);

        // Verify Dave (maker2): spent 100 NO, received 50 USDC
        assertCTFBalance(dave, no, 0);
        assertCollateralBalance(dave, 50_000_000);

        // Verify exchange holds nothing
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
        assertCTFBalance(address(exchange), no, 0);
    }

    /*//////////////////////////////////////////////////////////////
                    MULTI-MAKER COMPLEMENTARY WITH FEES
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Multi-maker COMPLEMENTARY with fees on all parties
    /// @dev Verifies correct fee deduction from each party
    ///
    /// Setup:
    ///   - Bob (taker): BUY 300 YES for 150 USDC, fee = 7.5 USDC (5%)
    ///   - Carla (maker1): SELL 100 YES for 50 USDC, fee = 2.5 USDC (5%)
    ///   - Dave (maker2): SELL 200 YES for 100 USDC, fee = 5 USDC (5%)
    ///
    /// Expected:
    ///   - Bob: 157.5 USDC -> 0, 0 YES -> 300 YES
    ///   - Carla: 0 USDC -> 47.5 (50 - 2.5 fee), 100 YES -> 0
    ///   - Dave: 0 USDC -> 95 (100 - 5 fee), 200 YES -> 0
    ///   - FeeReceiver: 0 -> 15 USDC (7.5 + 2.5 + 5)
    ///   - Exchange: holds 0 of everything
    function test_MultiMaker_Complementary_WithFees() public {
        // Setup balances (Bob needs extra for fee)
        dealUsdcAndApprove(bob, address(exchange), 157_500_000); // 150 + 7.5 fee
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);
        dealOutcomeTokensAndApprove(dave, address(exchange), yes, 200_000_000);

        // Create orders
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 150_000_000, 300_000_000, Side.BUY);
        Order memory maker1Order = _createAndSignOrder(carlaPK, yes, 100_000_000, 50_000_000, Side.SELL);
        Order memory maker2Order = _createAndSignOrderWithSalt(davePK, yes, 200_000_000, 100_000_000, Side.SELL, 2);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = maker1Order;
        makerOrders[1] = maker2Order;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 100_000_000;
        fillAmounts[1] = 200_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 2_500_000; // 2.5 USDC fee on maker1
        makerFeeAmounts[1] = 5_000_000; // 5 USDC fee on maker2

        // Execute match
        vm.prank(admin);
        exchange.matchOrders(
            conditionId,
            takerOrder,
            makerOrders,
            150_000_000, // takerFillAmount
            fillAmounts,
            7_500_000, // takerFeeAmount (7.5 USDC)
            makerFeeAmounts
        );

        // Verify Bob (taker): spent 157.5 USDC, received 300 YES
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 300_000_000);

        // Verify Carla (maker1): spent 100 YES, received 47.5 USDC (50 - 2.5 fee)
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 47_500_000);

        // Verify Dave (maker2): spent 200 YES, received 95 USDC (100 - 5 fee)
        assertCTFBalance(dave, yes, 0);
        assertCollateralBalance(dave, 95_000_000);

        // Verify fee receiver got all fees: 7.5 + 2.5 + 5 = 15 USDC
        assertCollateralBalance(feeReceiver, 15_000_000);

        // Verify exchange holds nothing
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
    }

    /*//////////////////////////////////////////////////////////////
                    TAKER SELL COMPLEMENTARY WITH TAKER FEE
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Taker SELL with fee deducted from proceeds
    /// @dev Verifies fee is correctly deducted from taker's collateral proceeds
    ///
    /// Setup:
    ///   - Bob (taker): SELL 100 YES for 50 USDC, fee = 2.5 USDC (5%)
    ///   - Carla (maker): BUY 100 YES for 50 USDC, fee = 0
    ///
    /// Expected:
    ///   - Bob: 0 USDC -> 47.5 (50 - 2.5 fee), 100 YES -> 0
    ///   - Carla: 50 USDC -> 0, 0 YES -> 100 YES
    ///   - FeeReceiver: 0 -> 2.5 USDC
    function test_Complementary_TakerSell_WithTakerFee() public {
        // Setup balances
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 100_000_000);
        dealUsdcAndApprove(carla, address(exchange), 50_000_000);

        // Create orders
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 50_000_000, Side.SELL);
        Order memory makerOrder = _createAndSignOrder(carlaPK, yes, 50_000_000, 100_000_000, Side.BUY);

        Order[] memory makerOrders = new Order[](1);
        makerOrders[0] = makerOrder;

        uint256[] memory fillAmounts = new uint256[](1);
        fillAmounts[0] = 50_000_000; // Fill maker fully (50 USDC)

        uint256[] memory makerFeeAmounts = new uint256[](1);
        makerFeeAmounts[0] = 0;

        // Execute match
        vm.prank(admin);
        exchange.matchOrders(
            conditionId,
            takerOrder,
            makerOrders,
            100_000_000, // takerFillAmount (100 YES)
            fillAmounts,
            2_500_000, // takerFeeAmount (2.5 USDC)
            makerFeeAmounts
        );

        // Verify Bob (taker): spent 100 YES, received 47.5 USDC (50 - 2.5 fee)
        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 47_500_000);

        // Verify Carla (maker): spent 50 USDC, received 100 YES
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, yes, 100_000_000);

        // Verify fee receiver got 2.5 USDC
        assertCollateralBalance(feeReceiver, 2_500_000);

        // Verify exchange holds nothing
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
    }

    /*//////////////////////////////////////////////////////////////
                    MULTI-MAKER TAKER SELL WITH FEES
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Multi-maker taker SELL with fees on all parties
    /// @dev Verifies taker fee is deducted from total proceeds
    ///
    /// Setup:
    ///   - Bob (taker): SELL 300 YES for 150 USDC, fee = 7.5 USDC (5%)
    ///   - Carla (maker1): BUY 100 YES for 50 USDC, fee = 2.5 USDC (5%)
    ///   - Dave (maker2): BUY 200 YES for 100 USDC, fee = 5 USDC (5%)
    ///
    /// Expected:
    ///   - Bob: 0 USDC -> 142.5 (150 - 7.5 fee), 300 YES -> 0
    ///   - Carla: 52.5 USDC -> 0 (50 + 2.5 fee), 0 YES -> 100 YES
    ///   - Dave: 105 USDC -> 0 (100 + 5 fee), 0 YES -> 200 YES
    ///   - FeeReceiver: 0 -> 15 USDC
    function test_MultiMaker_Complementary_TakerSell_WithFees() public {
        // Setup balances (makers need extra for fees)
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 300_000_000);
        dealUsdcAndApprove(carla, address(exchange), 52_500_000); // 50 + 2.5 fee
        dealUsdcAndApprove(dave, address(exchange), 105_000_000); // 100 + 5 fee

        // Create orders
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 300_000_000, 150_000_000, Side.SELL);
        Order memory maker1Order = _createAndSignOrder(carlaPK, yes, 50_000_000, 100_000_000, Side.BUY);
        Order memory maker2Order = _createAndSignOrderWithSalt(davePK, yes, 100_000_000, 200_000_000, Side.BUY, 2);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = maker1Order;
        makerOrders[1] = maker2Order;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 50_000_000; // Fill maker1 fully
        fillAmounts[1] = 100_000_000; // Fill maker2 fully

        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 2_500_000; // 2.5 USDC fee
        makerFeeAmounts[1] = 5_000_000; // 5 USDC fee

        // Execute match
        vm.prank(admin);
        exchange.matchOrders(
            conditionId,
            takerOrder,
            makerOrders,
            300_000_000, // takerFillAmount
            fillAmounts,
            7_500_000, // takerFeeAmount (7.5 USDC)
            makerFeeAmounts
        );

        // Verify Bob (taker): spent 300 YES, received 142.5 USDC (150 - 7.5 fee)
        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 142_500_000);

        // Verify Carla (maker1): spent 52.5 USDC, received 100 YES
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, yes, 100_000_000);

        // Verify Dave (maker2): spent 105 USDC, received 200 YES
        assertCollateralBalance(dave, 0);
        assertCTFBalance(dave, yes, 200_000_000);

        // Verify fee receiver got all fees: 7.5 + 2.5 + 5 = 15 USDC
        assertCollateralBalance(feeReceiver, 15_000_000);

        // Verify exchange holds nothing
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
    }

    /*//////////////////////////////////////////////////////////////
                    VARIED FILL AMOUNTS (DIFFERENT PRICES)
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Makers at different prices with varied fill amounts
    /// @dev Verifies each maker receives based on THEIR order's price ratio
    ///      For crossing: Taker BUY price must be >= Maker SELL price
    ///
    /// Setup:
    ///   - Bob (taker): BUY 300 YES for 180 USDC (price: 0.60)
    ///   - Carla (maker1): SELL 100 YES for 40 USDC (price: 0.40) - crosses at 0.60 >= 0.40
    ///   - Dave (maker2): SELL 200 YES for 100 USDC (price: 0.50) - crosses at 0.60 >= 0.50
    ///
    /// Taking amounts calculated from MAKER's ratio:
    ///   - Carla fills 100 YES -> taking = 100 * 40/100 = 40 USDC
    ///   - Dave fills 200 YES -> taking = 200 * 100/200 = 100 USDC
    ///   - Total taker pays: 40 + 100 = 140 USDC (under his limit of 180)
    ///
    /// Expected:
    ///   - Bob: 180 USDC -> 40 (refund), 0 YES -> 300 YES
    ///   - Carla: 0 USDC -> 40, 100 YES -> 0
    ///   - Dave: 0 USDC -> 100, 200 YES -> 0
    function test_VariedFillAmounts_DifferentPrices() public {
        // Setup balances
        dealUsdcAndApprove(bob, address(exchange), 180_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), yes, 100_000_000);
        dealOutcomeTokensAndApprove(dave, address(exchange), yes, 200_000_000);

        // Create orders with different prices
        // Taker: BUY 300 YES for 180 USDC (willing to pay 0.60 per YES)
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 180_000_000, 300_000_000, Side.BUY);

        // Maker1: SELL 100 YES for 40 USDC (price: 0.40) - better deal for taker
        Order memory maker1Order = _createAndSignOrder(carlaPK, yes, 100_000_000, 40_000_000, Side.SELL);

        // Maker2: SELL 200 YES for 100 USDC (price: 0.50) - still crosses
        Order memory maker2Order = _createAndSignOrderWithSalt(davePK, yes, 200_000_000, 100_000_000, Side.SELL, 2);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = maker1Order;
        makerOrders[1] = maker2Order;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 100_000_000; // Fill maker1 fully (100 YES)
        fillAmounts[1] = 200_000_000; // Fill maker2 fully (200 YES)

        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 0;
        makerFeeAmounts[1] = 0;

        // Execute match
        vm.prank(admin);
        exchange.matchOrders(
            conditionId,
            takerOrder,
            makerOrders,
            180_000_000, // takerFillAmount
            fillAmounts,
            0, // takerFeeAmount
            makerFeeAmounts
        );

        // Verify Bob (taker): spent 180 USDC, received 300 YES
        // Taker only needed 140 USDC (40 + 100), gets 40 USDC refund
        assertCollateralBalance(bob, 40_000_000);
        assertCTFBalance(bob, yes, 300_000_000);

        // Verify Carla (maker1): spent 100 YES, received 40 USDC (at her price)
        assertCTFBalance(carla, yes, 0);
        assertCollateralBalance(carla, 40_000_000);

        // Verify Dave (maker2): spent 200 YES, received 100 USDC (at his price)
        assertCTFBalance(dave, yes, 0);
        assertCollateralBalance(dave, 100_000_000);

        // Verify exchange holds nothing
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        MULTI-MAKER MINT WITH FEES
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Multi-maker MINT with fees
    /// @dev Fees are charged on collateral (makerAmount) for BUY orders
    ///
    /// Setup:
    ///   - Bob (taker): BUY 200 YES for 100 USDC, fee = 5 USDC
    ///   - Carla (maker1): BUY 100 NO for 50 USDC, fee = 2.5 USDC
    ///   - Dave (maker2): BUY 100 NO for 50 USDC, fee = 2.5 USDC
    ///
    /// Expected:
    ///   - Bob: 105 USDC -> 0, 0 YES -> 200 YES
    ///   - Carla: 52.5 USDC -> 0, 0 NO -> 100 NO
    ///   - Dave: 52.5 USDC -> 0, 0 NO -> 100 NO
    ///   - FeeReceiver: 0 -> 10 USDC
    function test_MultiMaker_Mint_WithFees() public {
        // Setup balances (include fees)
        dealUsdcAndApprove(bob, address(exchange), 105_000_000); // 100 + 5 fee
        dealUsdcAndApprove(carla, address(exchange), 52_500_000); // 50 + 2.5 fee
        dealUsdcAndApprove(dave, address(exchange), 52_500_000); // 50 + 2.5 fee

        // Create orders
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 100_000_000, 200_000_000, Side.BUY);
        Order memory maker1Order = _createAndSignOrder(carlaPK, no, 50_000_000, 100_000_000, Side.BUY);
        Order memory maker2Order = _createAndSignOrderWithSalt(davePK, no, 50_000_000, 100_000_000, Side.BUY, 2);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = maker1Order;
        makerOrders[1] = maker2Order;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 50_000_000;
        fillAmounts[1] = 50_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 2_500_000;
        makerFeeAmounts[1] = 2_500_000;

        // Execute match
        vm.prank(admin);
        exchange.matchOrders(
            conditionId,
            takerOrder,
            makerOrders,
            100_000_000,
            fillAmounts,
            5_000_000, // takerFeeAmount
            makerFeeAmounts
        );

        // Verify Bob (taker): spent 105 USDC, received 200 YES
        assertCollateralBalance(bob, 0);
        assertCTFBalance(bob, yes, 200_000_000);

        // Verify Carla (maker1): spent 52.5 USDC, received 100 NO
        assertCollateralBalance(carla, 0);
        assertCTFBalance(carla, no, 100_000_000);

        // Verify Dave (maker2): spent 52.5 USDC, received 100 NO
        assertCollateralBalance(dave, 0);
        assertCTFBalance(dave, no, 100_000_000);

        // Verify fee receiver got all fees: 5 + 2.5 + 2.5 = 10 USDC
        assertCollateralBalance(feeReceiver, 10_000_000);

        // Verify exchange holds nothing
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
        assertCTFBalance(address(exchange), no, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        MULTI-MAKER MERGE WITH FEES
    //////////////////////////////////////////////////////////////*/

    /// @notice Test: Multi-maker MERGE with fees
    /// @dev Fees are deducted from collateral proceeds for SELL orders
    ///
    /// Setup:
    ///   - Bob (taker): SELL 200 YES for 100 USDC, fee = 5 USDC
    ///   - Carla (maker1): SELL 100 NO for 50 USDC, fee = 2.5 USDC
    ///   - Dave (maker2): SELL 100 NO for 50 USDC, fee = 2.5 USDC
    ///
    /// Expected:
    ///   - Bob: 0 USDC -> 95 (100 - 5 fee), 200 YES -> 0
    ///   - Carla: 0 USDC -> 47.5 (50 - 2.5 fee), 100 NO -> 0
    ///   - Dave: 0 USDC -> 47.5 (50 - 2.5 fee), 100 NO -> 0
    ///   - FeeReceiver: 0 -> 10 USDC
    function test_MultiMaker_Merge_WithFees() public {
        // Setup balances
        dealOutcomeTokensAndApprove(bob, address(exchange), yes, 200_000_000);
        dealOutcomeTokensAndApprove(carla, address(exchange), no, 100_000_000);
        dealOutcomeTokensAndApprove(dave, address(exchange), no, 100_000_000);

        // Create orders
        Order memory takerOrder = _createAndSignOrder(bobPK, yes, 200_000_000, 100_000_000, Side.SELL);
        Order memory maker1Order = _createAndSignOrder(carlaPK, no, 100_000_000, 50_000_000, Side.SELL);
        Order memory maker2Order = _createAndSignOrderWithSalt(davePK, no, 100_000_000, 50_000_000, Side.SELL, 2);

        Order[] memory makerOrders = new Order[](2);
        makerOrders[0] = maker1Order;
        makerOrders[1] = maker2Order;

        uint256[] memory fillAmounts = new uint256[](2);
        fillAmounts[0] = 100_000_000;
        fillAmounts[1] = 100_000_000;

        uint256[] memory makerFeeAmounts = new uint256[](2);
        makerFeeAmounts[0] = 2_500_000;
        makerFeeAmounts[1] = 2_500_000;

        // Execute match
        vm.prank(admin);
        exchange.matchOrders(
            conditionId,
            takerOrder,
            makerOrders,
            200_000_000,
            fillAmounts,
            5_000_000, // takerFeeAmount
            makerFeeAmounts
        );

        // Verify Bob (taker): spent 200 YES, received 95 USDC (100 - 5 fee)
        assertCTFBalance(bob, yes, 0);
        assertCollateralBalance(bob, 95_000_000);

        // Verify Carla (maker1): spent 100 NO, received 47.5 USDC (50 - 2.5 fee)
        assertCTFBalance(carla, no, 0);
        assertCollateralBalance(carla, 47_500_000);

        // Verify Dave (maker2): spent 100 NO, received 47.5 USDC (50 - 2.5 fee)
        assertCTFBalance(dave, no, 0);
        assertCollateralBalance(dave, 47_500_000);

        // Verify fee receiver got all fees: 5 + 2.5 + 2.5 = 10 USDC
        assertCollateralBalance(feeReceiver, 10_000_000);

        // Verify exchange holds nothing
        assertCollateralBalance(address(exchange), 0);
        assertCTFBalance(address(exchange), yes, 0);
        assertCTFBalance(address(exchange), no, 0);
    }

    /*//////////////////////////////////////////////////////////////
                              HELPERS
    //////////////////////////////////////////////////////////////*/

    function _createAndSignOrderWithSalt(
        uint256 pk,
        uint256 tokenId,
        uint256 makerAmount,
        uint256 takerAmount,
        Side side,
        uint256 salt
    ) internal view returns (Order memory) {
        address maker = vm.addr(pk);
        Order memory order = _createOrder(maker, tokenId, makerAmount, takerAmount, side);
        order.salt = salt;
        order.signature = _signMessage(pk, exchange.hashOrder(order));
        return order;
    }
}
