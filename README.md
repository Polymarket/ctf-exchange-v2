# Polymarket CTF Exchange V2

The CTF Exchange V2 is the core smart contract system for trading [Conditional Token Framework](https://docs.gnosis.io/conditionaltokens/) (CTF) assets on Polymarket. It implements operator-driven order matching with support for multiple settlement types, signature schemes, and a wrapped collateral layer.

## Deployed Contracts

### Polygon

| Contract | Address |
|----------|---------|
| [CollateralToken](src/collateral/CollateralToken.sol) (impl) | [`0x6bBCef9f7ef3B6C592c99e0f206a0DE94Ad0925f`](https://polygonscan.com/address/0x6bBCef9f7ef3B6C592c99e0f206a0DE94Ad0925f) |
| [CollateralToken](src/collateral/CollateralToken.sol) (proxy) | [`0xC011a7E12a19f7B1f670d46F03B03f3342E82DFB`](https://polygonscan.com/address/0xC011a7E12a19f7B1f670d46F03B03f3342E82DFB) |
| [CollateralOnramp](src/collateral/CollateralOnramp.sol) | [`0x93070a847efEf7F70739046A929D47a521F5B8ee`](https://polygonscan.com/address/0x93070a847efEf7F70739046A929D47a521F5B8ee) |
| [CollateralOfframp](src/collateral/CollateralOfframp.sol) | [`0x2957922Eb93258b93368531d39fAcCA3B4dC5854`](https://polygonscan.com/address/0x2957922Eb93258b93368531d39fAcCA3B4dC5854) |
| [PermissionedRamp](src/collateral/PermissionedRamp.sol) | [`0xebC2459Ec962869ca4c0bd1E06368272732BCb08`](https://polygonscan.com/address/0xebC2459Ec962869ca4c0bd1E06368272732BCb08) |
| [CtfCollateralAdapter](src/adapters/CtfCollateralAdapter.sol) | [`0xADa100874d00e3331D00F2007a9c336a65009718`](https://polygonscan.com/address/0xADa100874d00e3331D00F2007a9c336a65009718) |
| [NegRiskCtfCollateralAdapter](src/adapters/NegRiskCtfCollateralAdapter.sol) | [`0xAdA200001000ef00D07553cEE7006808F895c6F1`](https://polygonscan.com/address/0xAdA200001000ef00D07553cEE7006808F895c6F1) |
| [CTFExchangeV2](src/exchange/CTFExchange.sol) | [`0xE111180000d2663C0091e4f400237545B87B996B`](https://polygonscan.com/address/0xE111180000d2663C0091e4f400237545B87B996B) |
| [NegRiskCtfExchangeV2](src/exchange/CTFExchange.sol) | [`0xe2222d279d744050d28e00520010520000310F59`](https://polygonscan.com/address/0xe2222d279d744050d28e00520010520000310F59) |

### Amoy

| Contract | Address |
|----------|---------|
| [CollateralToken](src/collateral/CollateralToken.sol) (impl) | [`0x28A4eaD5bD4847d36F6d046A45e827bdf7781C29`](https://amoy.polygonscan.com/address/0x28A4eaD5bD4847d36F6d046A45e827bdf7781C29) |
| [CollateralToken](src/collateral/CollateralToken.sol) (proxy) | [`0xC011a7E12a19f7B1f670d46F03B03f3342E82DFB`](https://amoy.polygonscan.com/address/0xC011a7E12a19f7B1f670d46F03B03f3342E82DFB) |
| [CollateralOnramp](src/collateral/CollateralOnramp.sol) | [`0x93070a847efEf7F70739046A929D47a521F5B8ee`](https://amoy.polygonscan.com/address/0x93070a847efEf7F70739046A929D47a521F5B8ee) |
| [CollateralOfframp](src/collateral/CollateralOfframp.sol) | [`0x2957922Eb93258b93368531d39fAcCA3B4dC5854`](https://amoy.polygonscan.com/address/0x2957922Eb93258b93368531d39fAcCA3B4dC5854) |
| [PermissionedRamp](src/collateral/PermissionedRamp.sol) | [`0xebC2459Ec962869ca4c0bd1E06368272732BCb08`](https://amoy.polygonscan.com/address/0xebC2459Ec962869ca4c0bd1E06368272732BCb08) |
| [CtfCollateralAdapter](src/adapters/CtfCollateralAdapter.sol) | [`0xADa100874d00e3331D00F2007a9c336a65009718`](https://amoy.polygonscan.com/address/0xADa100874d00e3331D00F2007a9c336a65009718) |
| [NegRiskCtfCollateralAdapter](src/adapters/NegRiskCtfCollateralAdapter.sol) | [`0xAdA200001000ef00D07553cEE7006808F895c6F1`](https://amoy.polygonscan.com/address/0xAdA200001000ef00D07553cEE7006808F895c6F1) |
| [CTFExchangeV2](src/exchange/CTFExchange.sol) | [`0xE111180000d2663C0091e4f400237545B87B996B`](https://amoy.polygonscan.com/address/0xE111180000d2663C0091e4f400237545B87B996B) |
| [NegRiskCtfExchangeV2](src/exchange/CTFExchange.sol) | [`0xe2222d279d744050d28e00520010520000310F59`](https://amoy.polygonscan.com/address/0xe2222d279d744050d28e00520010520000310F59) |

## Security

### Audits

| Auditor | Report |
|---------|--------|
| Quantstamp | [CTF Exchange V2 - Quantstamp - March 2026](audits/CTF%20Exchange%20V2%20-%20Quantstamp%20-%20March%202026.pdf) |
| Cantina | [CTF Exchange V2 - Cantina - March 2026](audits/CTF%20Exchange%20V2%20-%20Cantina%20-%20March%202026.pdf) |

### Bug Bounty

Security vulnerabilities can be reported through the [Cantina bug bounty program](https://cantina.xyz/bounties/ff945ca2-2a6e-4b83-b1b6-7a0cd3b94bea).

## Architecture

The exchange uses a **mixin composition pattern**, where each concern is isolated into its own abstract contract:

```
CTFExchange
├── Auth              — Admin/operator role management
├── Trading           — Order matching and settlement
│   ├── Hashing       — EIP-712 typed data hashing
│   ├── AssetOperations — ERC20/ERC1155 transfers, CTF mint/merge
│   ├── Events        — Assembly-optimized event emission
│   ├── Fees          — Fee validation and collection
│   ├── UserPausable  — Per-user pause with block delay
│   └── Signatures    — EOA, Proxy, Safe, EIP-1271 verification
├── Pausable          — Global trading pause
└── ERC1155TokenReceiver
```

### Contracts

```
src/
├── exchange/
│   ├── CTFExchange.sol                 — Main entry point
│   ├── interfaces/                     — Interface definitions
│   ├── libraries/
│   │   ├── Structs.sol                 — Order, OrderStatus, enums
│   │   ├── CalculatorHelper.sol        — Price math (assembly-optimized)
│   │   ├── TransferHelper.sol          — Unified ERC20/ERC1155 transfers
│   │   ├── Create2Lib.sol             — CREATE2 address computation
│   │   ├── PolyProxyLib.sol           — Proxy wallet address derivation
│   │   └── PolySafeLib.sol            — Gnosis Safe address derivation
│   └── mixins/                         — Modular functionality
├── adapters/
│   ├── CtfCollateralAdapter.sol        — CTF ↔ PMCT adapter
│   └── NegRiskCtfCollateralAdapter.sol — Negative Risk variant
└── collateral/
    ├── CollateralToken.sol             — PMCT (PolyMarket Collateral Token)
    ├── CollateralOnramp.sol            — Wrap USDC/USDCe → PMCT
    └── CollateralOfframp.sol           — Unwrap PMCT → USDC/USDCe
```

### Order Lifecycle

1. Users sign EIP-712 typed orders off-chain specifying token, amounts, and side (BUY/SELL)
2. The operator calls `matchOrders()` with a taker order and array of maker orders
3. The exchange validates signatures, checks prices cross, and determines the match type
4. Settlement executes based on match type:
   - **COMPLEMENTARY** (BUY vs SELL) — Direct peer-to-peer transfers, no CTF operations
   - **MINT** (both BUY) — Collateral split into outcome tokens via CTF
   - **MERGE** (both SELL) — Outcome tokens merged back into collateral via CTF

### Signature Types

| Type | Description |
|------|-------------|
| `EOA` | Standard ECDSA — signer must equal maker |
| `POLY_PROXY` | ECDSA + Polymarket proxy wallet ownership verification |
| `POLY_GNOSIS_SAFE` | ECDSA + Gnosis Safe ownership verification |
| `POLY_1271` | EIP-1271 smart contract wallet signature |

Orders can also be **preapproved** by the operator, bypassing signature validation for subsequent matches.

### Collateral System

The exchange trades in **PMCT** (PolyMarket Collateral Token), an ERC20 wrapper around USDC/USDCe:
- **CollateralOnramp**: Wraps supported assets into PMCT
- **CollateralOfframp**: Unwraps PMCT back to supported assets
- **CtfCollateralAdapter**: Bridges PMCT ↔ CTF operations (split/merge/redeem)

## Changes from V1

### New Features

- **Order preapproval** — Operator can preapprove orders, bypassing signature validation on match. Supports invalidation.
- **User self-pause** — Users can pause their own accounts with a configurable block delay (default 100 blocks), preventing order execution as an emergency recovery mechanism.
- **Builder and metadata fields** — Orders now carry `builder` (origin indicator) and `metadata` (hashed metadata) fields for richer order attribution.
- **Wrapped collateral (PMCT)** — New collateral token layer with onramp/offramp, replacing direct USDC usage. Enables the collateral adapter pattern for CTF interactions.
- **Configurable max fee rate** — Admin-settable maximum fee rate in basis points (default 500 = 5%), enforced per-order.

### Removed Features

- **`fillOrder` / `fillOrders`** — Removed in favor of the unified `matchOrders` entry point.
- **NonceManager** — Nonce-based order cancellation removed. Orders are tracked by hash with `OrderStatus` (filled + remaining).
- **Registry** — Token registration removed. Any valid CTF token ID can be traded directly.
- **Reentrancy guard** — Removed. The operator-only access pattern eliminates reentrancy vectors.
- **Mutable factory addresses** — `setProxyFactory()` / `setSafeFactory()` removed. Factory addresses are now immutable constructor parameters with address derivation computed in pure assembly.

### Gas Optimizations

V2 was built with gas efficiency as a primary design goal. The optimizations span every layer of the protocol. All numbers below are from equivalent `matchOrders` gas snapshot tests (EOA signatures, no fees).

#### V1 vs V2 Comparison

| Operation | Makers | V1 | V2 | Savings | % |
|-----------|--------|-----|-----|---------|---|
| Complementary | 1 | 207,402 | 134,594 | 72,808 | **-35%** |
| Complementary | 5 | 411,423 | 308,940 | 102,483 | **-25%** |
| Complementary | 10 | 666,818 | 527,180 | 139,638 | **-21%** |
| Complementary | 20 | 1,178,855 | 964,688 | 214,167 | **-18%** |
| Mint | 1 | 297,631 | 278,853 | 18,778 | **-6%** |
| Mint | 5 | 724,982 | 458,937 | 266,045 | **-37%** |
| Mint | 10 | 1,259,558 | 684,656 | 574,902 | **-46%** |
| Mint | 20 | 2,330,028 | 1,138,156 | 1,191,872 | **-51%** |
| Merge | 1 | 267,846 | 248,241 | 19,605 | **-7%** |
| Merge | 5 | 684,301 | 434,534 | 249,767 | **-37%** |
| Merge | 10 | 1,205,260 | 668,014 | 537,246 | **-45%** |
| Merge | 20 | 2,248,481 | 1,137,026 | 1,111,455 | **-49%** |
| Combo (comp+mint) | 10 | 954,055 | 683,141 | 270,914 | **-28%** |
| Combo (comp+mint) | 20 | 1,745,359 | 1,143,608 | 601,751 | **-34%** |
| Combo (comp+merge) | 10 | 953,338 | 679,820 | 273,518 | **-29%** |
| Combo (comp+merge) | 20 | 1,724,687 | 1,140,733 | 583,954 | **-34%** |

The biggest wins are on **multi-maker mint/merge** (up to 51% savings) where batched CTF operations eliminate per-maker `splitPosition`/`mergePositions` calls. Complementary matches see 18-35% savings from the peer-to-peer fast path.

#### Batched CTF Operations

For MINT/MERGE matches with multiple makers, V1 called `splitPosition` / `mergePositions` once per maker order. V2 accumulates totals across all makers and executes **a single CTF call** for the entire batch.

#### Assembly-Optimized Event Emission

All events (`OrderFilled`, `OrdersMatched`, `FeeCharged`) are emitted via direct `log2`/`log3`/`log4` assembly instructions with manually packed memory layouts, avoiding Solidity's ABI encoding overhead.

#### Storage-Packed Order Status

`OrderStatus` packs `bool filled` (1 byte) and `uint248 remaining` (31 bytes) into a single 32-byte storage slot. Updates use a single `SLOAD` + `SSTORE` with bit operations:

```solidity
// Read: single SLOAD
let packed := sload(status.slot)
filled := and(packed, 0xff)
remaining := shr(8, packed)

// Write: single SSTORE
sstore(status.slot, or(shl(8, remaining), iszero(remaining)))
```

#### Cross-Multiplication Price Validation

V1 computed unit prices via division for crossing checks. V2 uses **cross-multiplication** for complementary orders, avoiding division entirely:

```solidity
// V1: division-based price comparison
priceA = makerAmount_A * 1e18 / takerAmount_A
priceB = makerAmount_B * 1e18 / takerAmount_B

// V2: cross-multiplication (no division, no precision loss)
makerAmount_A * makerAmount_B >= takerAmount_A * takerAmount_B
```

#### Branchless Enum Arithmetic

Match type derivation and asset ID computation use arithmetic instead of conditionals:

```solidity
// Match type without branching
matchType := mul(add(takerOrderSide, 1), eq(takerOrderSide, makerOrderSide))

// Asset IDs without branching
makerAssetId := mul(side, tokenId)
takerAssetId := sub(tokenId, makerAssetId)
```

#### EIP-712 Hashing with `mcopy`

Struct hashing uses the `mcopy` opcode (EIP-5656) to copy order fields in a single operation instead of field-by-field `mstore` calls:

```solidity
mstore(ptr, ORDER_TYPEHASH)
mcopy(add(ptr, 0x20), order, 0x160)  // Copy 352 bytes in one instruction
result := keccak256(ptr, 0x180)
```

#### Pure Assembly Address Derivation

Proxy and Safe wallet address verification computes CREATE2 addresses entirely in assembly — constructing bytecode hashes from raw bytes and pre-computed immutables. No intermediate allocations or ABI encoding.

#### Other Optimizations

- **Custom errors** throughout — no revert strings in bytecode
- **Unchecked arithmetic** on 11 proven-safe operations (loop counters, post-validation subtraction)
- **Immutable factory references** — all factory addresses and bytecode hashes stored as immutables, eliminating storage reads on every signature verification
- **Lazy fee validation** — `maxFeeRateBps` storage is only read when the fee is non-zero
- **XOR conditional swaps** in price calculation — eliminates branches using `(A xor B xor B) = A` involution

## Development

### Prerequisites

Install [Foundry](https://github.com/foundry-rs/foundry/).

Foundry has daily updates, run `foundryup` to update `forge` and `cast`.

### Build

```sh
forge build
```

### Testing

Run all tests:

```sh
forge test
```

Run test functions matching a regex pattern:

```sh
forge test -m PATTERN
```

Run tests in contracts matching a regex pattern:

```sh
forge test --mc PATTERN
```

Set `-vvv` to see a stack trace for a failed test.

### Gas Snapshots

```sh
forge snapshot
```

### Configuration

- **Solidity**: 0.8.30
- **Optimizer runs**: 1,000,000
- **Fuzz runs**: 256 (default), 10,000 (intense profile)

