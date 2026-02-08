# Gas Snapshots: CTF Collateral Adapter vs Regular Exchange

## Overview
This document compares gas costs between the regular CTF Exchange and the CTF Exchange using the CTF Collateral Adapter (OutcomeTokenFactory).

## Test Results

### Complementary Orders (BUY vs SELL)
| Test Case | Regular Exchange | CTF Adapter | Difference |
|-----------|-----------------|-------------|------------|
| 1 maker   | 640,286         | 640,893     | +607 gas   |
| 5 makers  | 807,571         | 808,168     | +597 gas   |
| 10 makers | 1,018,155       | 1,018,914   | +759 gas   |

**Analysis**: Minimal gas overhead (~600-750 gas) when using CTF Adapter for complementary trades.

---

### Mint Operations (BUY vs BUY)
| Test Case | Regular Exchange | CTF Adapter | Difference |
|-----------|-----------------|-------------|------------|
| 1 maker   | 628,008         | 714,435     | +86,427 gas |
| 5 makers  | 803,529         | 889,988     | +86,459 gas |
| 10 makers | 1,023,852       | 1,110,278   | +86,426 gas |

**Analysis**: The CTF Adapter adds approximately **86k gas** overhead per mint operation. This is expected as the adapter requires additional contract calls to mint position tokens.

---

### Merge Operations (SELL vs SELL)
| Test Case | Regular Exchange | CTF Adapter | Difference |
|-----------|-----------------|-------------|------------|
| 1 maker   | 724,004         | 810,165     | +86,161 gas |
| 5 makers  | 904,662         | 990,875     | +86,213 gas |
| 10 makers | 1,131,413       | 1,217,609   | +86,196 gas |

**Analysis**: Similar to mint operations, merge operations add approximately **86k gas** overhead when using the CTF Adapter.

---

### Combo: Complementary + Mint
| Test Case | Regular Exchange | CTF Adapter | Difference |
|-----------|-----------------|-------------|------------|
| 10 makers | 1,334,043       | 1,420,768   | +86,725 gas |
| 20 makers | 1,797,275       | 1,870,572   | +73,297 gas |

**Analysis**: Mixed operations show gas overhead scales with the proportion of mint operations in the batch.

---

### Combo: Complementary + Merge
| Test Case | Regular Exchange | CTF Adapter | Difference |
|-----------|-----------------|-------------|------------|
| 10 makers | 1,320,181       | 1,406,638   | +86,457 gas |
| 20 makers | 1,781,233       | 1,857,515   | +76,282 gas |

**Analysis**: Similar to complementary+mint, the overhead scales with the proportion of merge operations.

---

## Key Findings

### 1. **Complementary Trades** (Direct Token Swaps)
- **Overhead**: ~600-750 gas
- **Impact**: Negligible (<0.1% increase)
- **Reason**: No minting/burning required, just token transfers

### 2. **Mint Operations** (Creating Position Tokens)
- **Overhead**: ~86,000 gas per operation
- **Impact**: ~13.8% increase
- **Reason**: Additional contract calls to OutcomeTokenFactory adapter

### 3. **Merge Operations** (Burning Position Tokens)
- **Overhead**: ~86,000 gas per operation
- **Impact**: ~12% increase
- **Reason**: Additional contract calls to OutcomeTokenFactory adapter

### 4. **Scalability**
- Gas overhead remains relatively constant per operation type
- Batch operations maintain efficiency with the adapter
- Larger batches show slightly better relative performance

---

## Technical Implementation

### Test File Location
`src/test/GasSnapshotsCtfAdapter.t.sol`

### Setup Differences
The CTF Adapter tests use a different exchange initialization:

```solidity
// Regular Exchange
outcomeTokenFactory: address(ctf)

// CTF Adapter Exchange
outcomeTokenFactory: address(adapter)  // CtfCollateralAdapterMock
```

### Running the Tests
```bash
# Run all CTF Adapter gas snapshot tests
forge test --match-contract GasSnapshotsCtfAdapter_Test --gas-report

# Compare with regular exchange
forge test --match-contract GasSnapshots_Test --gas-report
```

---

## Recommendations

### When to Use CTF Adapter
1. **Required for compliance**: When regulatory requirements mandate using the adapter
2. **Complementary-heavy workloads**: Minimal gas impact for direct swaps
3. **Mixed operations**: Acceptable overhead for diverse trading patterns

### When to Use Regular Exchange
1. **Mint/Merge-heavy workloads**: Save ~86k gas per operation
2. **High-frequency trading**: Every gas unit counts
3. **Gas-sensitive applications**: Where 10-15% overhead is significant

---

## Gas Optimization Opportunities

Based on the analysis, potential optimizations for the CTF Adapter:

1. **Batch Minting/Burning**: Could reduce per-operation overhead
2. **Inline Operations**: Consider inlining adapter calls for common patterns
3. **Storage Optimization**: Reduce SSTORE operations in adapter logic

---

## Conclusion

The CTF Collateral Adapter introduces:
- **Minimal overhead** (~600 gas) for complementary trades
- **Moderate overhead** (~86k gas) for mint/merge operations
- **Predictable scaling** across batch sizes

The overhead represents a reasonable trade-off when the adapter functionality is required, with complementary trades remaining highly efficient.
