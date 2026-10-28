# amoy-executor-operators

Authorizes the 400 CLOB executor EOAs of preprod Amoy as operators of the two legacy venues,
`ctfExchangeV2` (`0xE1111800…`) and `negRiskCtfExchangeV2` (`0xe2222d27…`). Requested on Slack on
2026-10-29 (clob-execution, executor operators on preprod Amoy). ExchangeV3 (`exchange`) is
polymarket-v2's `v1.4.0-amoy-executor-operators`, with the same list. No production contract
changes.

The release runs on `polygon-amoy` and nowhere else. The book records no version of
ctf-exchange-v2, so the manifest has neither `from` nor `to` and moves no version; the folder is
named without one for the same reason. Every script calls `requireAmoy()`, which refuses a book
for any chain but 80002.

## Why a batcher

The venues' admin is the authority EOA `0xcA71EA69…`, on the `direct` route. An EOA sends one call
per transaction, so 800 `addOperator` calls would be 800 steps. Instead the release deploys
`ExecutorOperatorBatcher` and, for each venue in turn, the authority makes it an admin and then has
it add every missing executor and remove its own admin role in one transaction: five transactions
in all.

The batcher answers to the operating key alone:

- `owner` is immutable and is the book's authority at deploy time. `grantOperators` reverts with
  `NotOwner` for any other caller, even while the batcher holds a venue's admin role.
- The two venues are immutable (`UnknownVenue` for any other address), and the executors are the
  constant list compiled into it. Even the owner can make it do nothing but this grant.
- It needs the venue's admin role to run (`NotVenueAdmin`) and gives it up in the same transaction.
  The venues are done one after the other, so it administers at most one venue at a time, and
  neither once the release completes.
- `owner()` is also how Lattice governs it: the deploy step's `route: direct` binding is recorded
  only once the chain shows the authority owns it.

## The executors

`ExecutorOperators.sol` holds the list as a packed `bytes` constant, one line per address with its
index, in the order of `clob_execution_amoy_preprod.csv` (sha256 `5a689298…`; 400 rows, indices
0–399). It is the same list, in the same order, as polymarket-v2's release. Checked on
2026-10-29: 400 distinct, EIP-55 addresses, none with code on Amoy, none an operator of either
venue.

## Steps

| Step | Kind | Runs |
|---|---|---|
| `pre-change-checks` | `verify` (test) | `test/PreChange.t.sol` |
| `deploy-operator-batcher` | `deploy` | `1-DeployExecutorOperatorBatcher.s.sol`: CREATE2, `skipIfDeployed`, bound as `executorOperatorBatcher` on `direct` |
| `check-batcher-bytecode` | `verify` (bytecode) | full match against the pinned commit |
| `post-deploy-checks` | `verify` (test) | `test/PostDeploy.t.sol`: the lock and the rehearsal |
| `add-ctf-exchange-batcher-admin` | `propose`, `direct` | `2-AddCtfExchangeBatcherAdmin.s.sol`: `ctfExchangeV2.addAdmin(batcher)` |
| `grant-ctf-exchange-operators` | `propose`, `direct` | `3-GrantCtfExchangeOperators.s.sol`: `batcher.grantOperators(ctfExchangeV2)` |
| `add-neg-risk-ctf-exchange-batcher-admin` | `propose`, `direct` | `4-AddNegRiskCtfExchangeBatcherAdmin.s.sol`: `negRiskCtfExchangeV2.addAdmin(batcher)` |
| `grant-neg-risk-ctf-exchange-operators` | `propose`, `direct` | `5-GrantNegRiskCtfExchangeOperators.s.sol`: `batcher.grantOperators(negRiskCtfExchangeV2)` |
| `post-change-checks` | `verify` (test) | `test/PostChange.t.sol` |

Each propose step is followed by a plan verify step. Registration adds an explorer verify step after
the deploy.

Every plan is idempotent and `skipIfEmpty`. The admin grant builds nothing once the batcher is an
admin or the venue authorizes every executor. The grant builds nothing once the batcher holds no
admin role and every executor is authorized, and refuses to build while executors are missing and
the batcher is not an admin. A resumed or re-registered run proposes nothing that has already
landed.

## Tests

- `PreChange.t.sol`: the book is Amoy's, and the list is 400 distinct EOAs, none an operator of
  either venue. The authority is an EOA administering both venues, and the book holds no batcher
  yet.
- `PostDeploy.t.sol`:
  - The batcher is owned by the authority, bound to the book's two venues, and carries the list in
    order. It administers neither venue.
  - A stranger, an executor and a venue are each refused with `NotOwner`, even once it is admin.
  - The owner is refused on an unknown venue (`UnknownVenue`) and on a venue it does not
    administer (`NotVenueAdmin`).
  - Then the four plans are applied as the authority on the fork, in step order. Each is the exact
    expected call, and the grant refuses to build before the admin grant. Afterwards every executor
    operates the venue, the batcher administers neither venue, and no plan builds again.
- `PostChange.t.sol`: every executor operates both venues and administers neither, the authority
  still administers both, and the batcher neither. No plan builds again. The first and last
  executor pass each venue's operator gate (`invalidatePreapprovedOrder`) where a stranger does not.

## Proving it

From this commit:

```
lattice test ./script/releases/amoy-executor-operators/release.json --env polygon-amoy --repo . \
  --deployer unlocked:0xcA71EA69c54c163D17beB90BeB8D001E1Eb538A1
```

Nothing is sent anywhere but an anvil fork, and nothing is written to the state repository. It
completes: all 14 steps done, the batcher's bytecode a full match, all four plans re-derived
exactly, and 8 tests in four suites passed.

## Running it on Amoy

Every step signs as the authority `0xcA71EA69…`. Register from the merged commit, so the pinned
commit stays reachable.

```
lattice release register amoy-executor-operators --env polygon-amoy --repo .
lattice run --env polygon-amoy --release <id> --repo . \
  --sender account:create3-operator:$HOME/.lattice/keys/create3-operator.password
```
