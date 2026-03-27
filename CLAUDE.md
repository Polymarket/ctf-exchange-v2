# CLAUDE.md

## Project Overview

Polymarket's CTF Exchange v2 — an EIP-712 order-matching exchange for Conditional Tokens Framework (CTF) assets. Operators match signed off-chain orders on-chain with gas-optimized settlement paths. Built with Foundry and Solady.

Core concepts:
- **CTFExchange**: Main entry point. Mixin-based architecture combining Auth, Fees, Signatures, Trading, Pausable, and ERC1155TokenReceiver. Operator-gated order matching with admin controls.
- **Order Matching**: Three settlement paths — COMPLEMENTARY (BUY vs SELL, direct P2P transfers), MINT (both BUY, split collateral into outcome tokens), MERGE (both SELL, merge outcome tokens back to collateral).
- **Adapters**: CtfCollateralAdapter bridges CollateralToken ↔ ConditionalTokens (split/merge/redeem). NegRiskCtfCollateralAdapter extends it for NegRisk markets with position conversion.
- **CollateralToken**: UUPS-upgradeable ERC20 (pUSD, 6 decimals) wrapping USDC/USDCe, with permissionless onramp/offramp and EIP-712 witness-signed PermissionedRamp.

## Post-Audit Policy

This codebase has been audited. All future changes must follow these constraints:

- **Fixes only**: Only bug fixes and scoped improvements are allowed. No major refactors.
- **Minimal diffs**: Keep changes tightly scoped to the fix. Do not restructure surrounding code, rename variables, reorder functions, or "clean up" adjacent code.
- **Do NOT modify existing NatSpec** unless the fix directly changes the documented behavior.
- **Do NOT modify existing test setup** (BaseExchangeTest, TestHelper, mocks) unless the fix requires it.
- **New code requirements**: All new or modified production code must include:
  1. NatSpec documentation (see NatSpec Documentation section)
  2. Unit tests covering every new line and branch (see Testing section)
- **Gas snapshots**: If a fix changes gas usage, regenerate `.gas-snapshot` with `forge snapshot`.

## Gas Consciousness

This codebase is heavily gas-optimized — assembly-level event emission (`log4`/`log3`/`log2` in `Events.sol`), packed storage slots (`OrderStatus` packs `filled` + `remaining` into 32 bytes), COMPLEMENTARY settlement that eliminates exchange intermediary transfers, inline assembly for CREATE2 and price calculations, and batch CTF operations. Every change must respect this standard.

Before making any change, think hard about gas impact:

- **Always call out** why a change is necessary and what the trade-offs are with respect to gas. If a fix increases gas, explicitly state the cost and justify why correctness or security outweighs it.
- **Prefer gas-efficient patterns**: Use assembly where the codebase already does (events, hashing, address computation). Avoid unnecessary storage reads/writes. Batch operations where possible. Use Solady over OpenZeppelin.
- **Measure impact**: Run `forge snapshot` before and after every change and compare the `.gas-snapshot` diff. If gas increases substantially on hot paths (order matching, settlement), flag it for review.
- **Storage layout matters**: Pack related fields into single slots. Avoid adding new storage variables to frequently-read contracts without considering SLOAD cost.
- **Hot path awareness**: `matchOrders` → `_matchOrders` → `_settleComplementary` / `_settleMakerOrders` is the hot path. Any gas regression here affects every trade.

## Build & Verification Commands

```bash
forge build        # Compile
forge test         # Run all tests
forge fmt          # Format all files
forge snapshot     # Regenerate .gas-snapshot
```

**CI** (`.github/workflows/test.yml`) runs: `forge fmt --check`, `forge build --sizes`, `forge test -vvv`.

After every code change, run all four commands in order and fix any issues before considering the task complete.

## Project Structure

```
src/
├── exchange/
│   ├── CTFExchange.sol                    # Main contract — operator-gated matchOrders, preapproveOrder
│   ├── interfaces/
│   │   ├── IAuth.sol                      # Auth events/errors (IAuthEE)
│   │   ├── IAssets.sol                    # Asset address getters
│   │   ├── IConditionalTokens.sol         # CTF interface
│   │   ├── IFees.sol                      # Fee events/errors (IFeesEE)
│   │   ├── IPausable.sol                  # Pause events/errors (IPausableEE)
│   │   ├── ISignatures.sol                # Signature events/errors (ISignaturesEE)
│   │   ├── ITrading.sol                   # Trading events/errors (ITradingEE)
│   │   ├── IUserPausable.sol              # User pause events/errors (IUserPausableEE)
│   │   ├── IOutcomeTokenFactory.sol       # Outcome token factory interface
│   │   └── ISafeFactory.sol               # Gnosis Safe factory interface
│   ├── mixins/
│   │   ├── Auth.sol                       # Admin/Operator role management
│   │   ├── Assets.sol                     # Collateral, CTF, OutcomeTokenFactory addresses
│   │   ├── AssetOperations.sol            # CTF mint/merge/transfer operations
│   │   ├── ERC1155TokenReceiver.sol       # ERC1155 receive callbacks
│   │   ├── Events.sol                     # Optimized event emission (log4/log3/log2)
│   │   ├── Fees.sol                       # Fee receiver, max fee rate, validation
│   │   ├── Hashing.sol                    # EIP-712 order hashing
│   │   ├── Pausable.sol                   # Global trading pause
│   │   ├── PolyFactoryHelper.sol          # Proxy/Safe wallet address computation
│   │   ├── Signatures.sol                 # Multi-type signature validation (EOA, Proxy, Safe, 1271)
│   │   ├── Trading.sol                    # Core matching: complementary/mint/merge settlement
│   │   └── UserPausable.sol               # Per-user pause with block delay
│   └── libraries/
│       ├── Structs.sol                    # Order, OrderStatus, Side, MatchType, SignatureType
│       ├── CalculatorHelper.sol           # Price/amount calculations, crossing checks
│       ├── TransferHelper.sol             # ERC20/ERC1155 transfer wrappers (Solady)
│       ├── PolySafeLib.sol                # Gnosis Safe CREATE2 address derivation
│       ├── PolyProxyLib.sol               # Polymarket Proxy CREATE2 address derivation
│       └── Create2Lib.sol                 # Generic CREATE2 computation
├── adapters/
│   ├── CtfCollateralAdapter.sol           # CollateralToken ↔ CTF bridging (split/merge/redeem)
│   ├── NegRiskCtfCollateralAdapter.sol    # NegRisk extension with convertPositions
│   ├── interfaces/
│   │   ├── IConditionalTokens.sol         # CTF interface (adapter-specific)
│   │   └── INegRiskAdapter.sol            # NegRisk adapter interface
│   └── libraries/
│       ├── CTFHelpers.sol                 # positionIds(), partition()
│       └── CTHelpers.sol                  # getConditionId(), getCollectionId(), getPositionId()
├── collateral/
│   ├── CollateralToken.sol                # UUPS ERC20 (pUSD, 6 decimals) — wrap/unwrap with callbacks
│   ├── CollateralOnramp.sol               # Permissionless USDC/USDCe → pUSD
│   ├── CollateralOfframp.sol              # Permissionless pUSD → USDC/USDCe
│   ├── PermissionedRamp.sol               # EIP-712 witness-signed wrap/unwrap with nonces
│   ├── abstract/
│   │   ├── CollateralErrors.sol           # Shared collateral errors
│   │   └── Pausable.sol                   # Per-asset pause control
│   └── interfaces/
│       ├── ICollateralToken.sol            # CollateralToken interface
│       └── ICollateralTokenCallbacks.sol   # Callback interface for wrap/unwrap
├── scripts/
│   └── ExchangeDeployment.s.sol           # Deployment script
└── test/                                  # All tests, helpers, and mocks
    ├── BaseExchangeTest.sol               # Base: deploys exchange, order helpers, deal helpers
    ├── CTFExchange.t.sol                  # Auth, pause, fees, order validation, user pause
    ├── MatchOrders.t.sol                  # Complementary, mint, merge, fees, edge cases
    ├── BalanceDeltas.t.sol                # Multi-maker balance verification
    ├── Preapproved.t.sol                  # Preapproval mechanism
    ├── ERC1271Signature.t.sol             # Smart contract wallet signatures
    ├── CtfCollateralAdapter.t.sol          # CTF adapter operations
    ├── MatchOrdersCtfCollateralAdapter.t.sol
    ├── NegRiskCtfCollateralAdapter.t.sol
    ├── MatchOrdersNegRiskCtfCollateralAdapter.t.sol
    ├── CollateralOnramp.t.sol
    ├── CollateralOfframp.t.sol
    ├── CollateralToken.t.sol
    ├── CollateralSetup.t.sol
    ├── PermissionedRamp.t.sol
    ├── GasSnapshots.t.sol                 # Gas measurement (1–20 makers)
    ├── GasSnapshotsCtfCollateralAdapter.t.sol
    ├── GasSnapshotsNegRiskCtfCollateralAdapter.t.sol
    ├── GasSnapshotsProxy.t.sol
    ├── GasSnapshotsSafe.t.sol
    ├── libraries/
    │   ├── CalculatorHelper.t.sol         # Fuzz tests for price/amount/crossing
    │   ├── PolyProxyLib.t.sol             # Proxy address derivation
    │   └── PolySafeLib.t.sol              # Safe address derivation
    └── dev/
        ├── TestHelper.sol                 # Abstract base: 8 accounts, balance checkpoints, helpers
        ├── CollateralSetup.sol            # Collateral system deployment library
        ├── NegRiskAdapterSetUp.sol        # NegRisk adapter deployment
        ├── util/
        │   ├── Deployer.sol               # FFI-based deployment (ConditionalTokens, NegRiskAdapter)
        │   └── vm.sol                     # Foundry vm reference
        └── mocks/
            ├── USDC.sol                   # Simple ERC20 mock
            ├── USDCe.sol                  # USDCe variant
            ├── ERC1271Mock.sol            # Smart contract signature validation
            ├── ToggleableERC1271Mock.sol   # 1271 mock with disable + ERC1155 receiver
            ├── CollateralVault.sol         # Collateral custody mock
            ├── MockProxyFactory.sol        # Proxy factory mock
            ├── MockSafeFactory.sol         # Safe factory mock
            └── CtfCollateralAdapterMock.sol
```

## Solidity Conventions

### License

- Production contracts (exchange, adapters, collateral, scripts): `// SPDX-License-Identifier: BUSL-1.1`
- Tests and dev helpers: `// SPDX-License-Identifier: MIT`
- Exception: `src/adapters/libraries/CTHelpers.sol` retains `LGPL-3.0-or-later` (forked from Gnosis Conditional Tokens).
- When adding new production files, always use `BUSL-1.1`. Do not use MIT for production code.

### Pragma

- Production contracts (exchange, adapters, collateral): `pragma solidity 0.8.34;` (exact)
- Mixins, interfaces, exchange libraries: `pragma solidity <0.9.0;`
- Tests and dev helpers: `pragma solidity <0.9.0;` or `pragma solidity 0.8.34;`
- Legacy adapter libraries (CTHelpers): `pragma solidity >=0.5.1;`
- When adding new files, match the pragma style of neighboring files in the same directory.

### Formatting

Enforced by `forge fmt` with `foundry.toml`:
- Line length: **120 characters**
- Tab width: 4 spaces
- Bracket spacing: enabled
- Comment wrapping: enabled
- Single-line statement blocks: `single`
- Always run `forge fmt` before considering any change complete.

### File & Contract Layout

Standard section ordering within contracts, using these separators:

```solidity
/*--------------------------------------------------------------
                          SECTION NAME
--------------------------------------------------------------*/
```

Section order: STATE → CONSTANTS → MODIFIERS → CONSTRUCTOR → VIEW → ONLY OPERATOR → ONLY ADMIN → INTERNAL.

### Imports

- External libs: `import {Type} from "@solady/src/path/File.sol";` or `import {Type} from "@forge-std/src/File.sol";`
- Cross-domain src: `import {Type} from "@ctf-exchange-v2/src/domain/File.sol";`
- Same-domain src: `import {Type} from "./File.sol";` or `import {Type} from "../File.sol";`
- Remappings are defined in `foundry.toml` under `remappings`. Do not create a `remappings.txt` file.
- Group external imports first, then local imports, separated by a blank line.

### Naming

- Internal/private functions: `_functionName()`
- Constants: `UPPER_SNAKE_CASE`
- Function params: `_camelCase` with leading underscore
- Libraries: `PascalCase` (e.g., `CalculatorHelper`, `TransferHelper`)
- Test accounts: lowercase words (e.g., `alice`, `bob`, `carla`)

### Errors & Events

- Domain-specific errors and events are defined in interface files (e.g., `IAuthEE`, `IFeesEE`, `ITradingEE` in `src/exchange/interfaces/`). Collateral errors live in `CollateralErrors` abstract contract.
- Test contracts inherit interface event/error contracts to use selectors directly in assertions.

## NatSpec Documentation

Every **new** contract, interface, library, error, event, and function in `src/` (excluding `test/` and `dev/`) must have NatSpec. Do NOT retroactively add NatSpec to existing audited code unless the fix changes the documented behavior.

### Contract / Interface / Library Level

```solidity
/// @title ContractName
/// @notice Brief one-line description.
/// @author Polymarket
```

### Errors

```solidity
/// @notice Thrown when the caller is not authorized.
error Unauthorized();
```

### Events

```solidity
/// @notice Emitted when the fee receiver is updated.
/// @param receiver The new fee receiver address.
event FeeReceiverUpdated(address receiver);
```

### Functions

```solidity
/// @notice What it does (one line).
/// @dev Implementation detail or access restriction (only if non-obvious).
/// @param _name Description.
/// @return name Description.
```

### Struct Fields

```solidity
struct Order {
    /// @notice Unique salt to ensure entropy
    uint256 salt;
    /// @notice Maker of the order, i.e the source of funds
    address maker;
}
```

### forge fmt and NatSpec stability

`forge fmt` with `wrap_comments = true` re-flows `///` comment blocks. This can merge a `@param` or `@return` tag into the preceding line's prose, breaking NatSpec parsing. To prevent this:

- Keep each `@notice`, `@dev`, `@param`, `@return` description under ~100 characters so it fits on one `///` line (with the 4-space indent and `/// ` prefix, that's ~120 total).
- After adding NatSpec, always run `forge fmt` then verify no tags were merged: `grep -rn '/// .* @\(param\|dev\|return\|notice\)' src/ --include='*.sol'` should return no matches.
- If `forge fmt` merges a tag, shorten the preceding description.

### When NOT to document

- `test/` and `dev/` directories (test files, helpers, mocks)
- Existing audited code (unless the fix changes behavior)

## Testing

### Framework & Configuration

- **Foundry** with `forge-std/Test.sol`
- **FFI enabled**: Used by `Deployer.sol` to deploy ConditionalTokens and NegRiskAdapter from `artifacts/`
- **Fuzz**: 256 runs default, `profile.intense` for 10,000 runs
- **Optimizer**: 1,000,000 runs (production-level optimization)

### Test Location

Tests live in `src/test/`. Dev helpers and mocks live in `src/test/dev/` and `src/test/dev/mocks/`.

### Test Structure

Tests use flat contracts extending a base test:

```solidity
contract MatchOrdersTest is BaseExchangeTest {
    function test_MatchOrders_Complementary() public { ... }
    function test_MatchOrders_Mint() public { ... }
    function test_MatchOrders_revert_NotCrossing() public { ... }
}
```

- **BaseExchangeTest** (`src/test/BaseExchangeTest.sol`): Deploys USDC, ConditionalTokens, CTFExchange. Provides order creation/signing helpers, deal helpers, balance assertion helpers. Extends `TestHelper`.
- **TestHelper** (`src/test/dev/TestHelper.sol`): 8 pre-labeled accounts (`alice` through `henry`), balance checkpoint system, `with()` modifier for prank scoping, ERC20 `deal`/`approve`/`dealAndApprove` helpers, `advance(blocks)` for block manipulation.
- **CollateralSetup** (`src/test/dev/CollateralSetup.sol`): Deploys full collateral system (USDC, USDCe, vault, CollateralToken proxy, onramp, offramp, permissionedRamp).

### Test Function Naming

- Happy path: `test_ContractName_Description()`
- Revert / failure: `test_ContractName_revert_Reason()`
- Fuzz tests: `test_ContractName_FuzzDescription(uint64 _param, ...)`

### Adding New Tests

1. **Append to the existing test file** for the contract being tested (e.g., `MatchOrders.t.sol` for Trading changes, `CTFExchange.t.sol` for admin/fee changes).
2. If no suitable file exists, create a new `.t.sol` file in `src/test/` following the same pattern.
3. **Never** add test functions to base test contracts (`BaseExchangeTest`, `TestHelper`).

### Coverage Requirements for New Code

- **Goal**: 100% line and branch coverage for all new or modified production code.
- **Every positive test** must include `vm.expectEmit` for any event-emitting code path, and `assertEq` for every state/balance change.
- **Every revert test** must use `vm.expectRevert(ErrorName.selector)` with the specific error.

### Gas Snapshots

Gas snapshot tests use `vm.pauseGasMetering()` for setup and `vm.resumeGasMetering()` before the measured operation. The `.gas-snapshot` file tracks gas costs across match types and maker counts.

After any change that affects gas:
```bash
forge snapshot
```

### Patterns

- Use `vm.prank(address)` / `vm.startPrank` / `vm.stopPrank` for caller impersonation
- Use `vm.expectRevert(ErrorName.selector)` before the reverting call
- Use `vm.expectEmit(true, true, true, true)` + `emit EventName(...)` before the emitting call
- Assertions: `assertEq()`, `assertTrue()`, `assertFalse()`
- Balance helpers: `assertCollateralBalance()`, `assertCTFBalance()`, `getCTFBalance()`
- Deal helpers: `dealUsdcAndApprove()`, `dealOutcomeTokensAndApprove()`

### Test Accounts

| Name | Address | Notes |
|------|---------|-------|
| alice | address(1) | Used as admin in exchange tests |
| brian | address(2) | General purpose |
| carly | address(3) | General purpose |
| dylan | address(4) | General purpose |
| erica | address(5) | General purpose |
| frank | address(6) | General purpose |
| grace | address(7) | General purpose |
| henry | address(8) | General purpose |
| bob | vm.addr(0xB0B) | Exchange test maker/operator (has private key) |
| carla | vm.addr(0xCA414) | Exchange test maker/operator (has private key) |

## Dependencies

- **Solady**: Gas-optimized contracts (ERC20, ERC1155, EIP712, ECDSA, SafeTransferLib, LibClone, UUPSUpgradeable, Initializable, OwnableRoles)
- **forge-std**: Foundry testing framework

## Keeping This File Up to Date

After completing any task that changes project conventions, structure, or workflows, update this file to reflect those changes. Specifically:

- **New contracts or directories**: Update the Project Structure tree.
- **New dependencies**: Add to the Dependencies section.
- **Changed conventions**: If a naming pattern, test pattern, pragma version, or formatting rule changes, update the relevant section so future sessions follow the new convention.
- **Solidity version bumps**: When bumping the Solidity version:
  1. Update `solc` in `foundry.toml`.
  2. Replace the exact version in all `pragma solidity X.Y.Z;` lines under `src/` (production, tests, scripts, mocks — everything that uses the exact pragma). Do **not** touch range pragmas (`<0.9.0`, `>=0.5.1`) or files under `lib/`.
  3. Update the version references in the **Pragma** subsection of this file to match.
  4. Run `forge build && forge test && forge fmt` to verify nothing breaks.
- **New error/event contracts**: Note where they live in the Errors & Events subsection.
- **New build steps or CI changes**: Update Build & Verification Commands.
- **New test helpers or accounts**: Update the Testing section.
- **New contracts or functions**: Every new production contract, function, error, event, modifier, and struct must include NatSpec following the patterns in the NatSpec Documentation section.
- **Post-audit policy changes**: If the audit constraint is lifted, update the Post-Audit Policy section accordingly.

Do not add session-specific notes (current task details, in-progress work). This file should only contain stable, reusable instructions.
