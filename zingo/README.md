# Zingo & Zingolib

## Background information

Zingo/Zingolib is a fork of [Zecwallet](../zecwallet/README.md) and, as a result, many structures are similar.
It uses a bespoke format for storing wallet data on disk.

The top-level functions used to write/read wallet data are in `zingolib/src/wallet/disk.rs#48`.

## Schema

The overall schema looks as follows:

| Keyname                             | Value                                       | Description                                             |
| ----------------------------------- | ------------------------------------------- | ------------------------------------------------------- |
| LightWallet Version                 | u64 = 30                                    | LightWallet struct version.                             |
| Keys                                | [`WalletCapability`](#walletcapability)     | Transaction Context Keys.                               |
| Blocks                              | Vector<[`BlockData`](#blockdata)>           | Last 100 blocks, used for reorgs.                       |
| Transaction Metadata Set            | [`TxMap`](#txmap)                           | HashMap of all transactions in a wallet, keyed by txid. |
| ChainType                           | String                                      |                                                         |
| Wallet Options                      |                                             |                                                         |
| <span id="birthday">Birthday</span> | u64                                         |                                                         |
| Verified Tree                       | Option<[`TreeState`](#treestate)>           | Highest verified block                                  |
| Price                               | [`WalletZecPriceInfo`](#walletzecpriceinfo) | Price information.                                      |
| Seed Bytes                          | Vector<u8>                                  | Seed entropy.                                           |
| Mnemonic                            | [`Mnemonic`](#mnemonic)                     | ZIP 339 mnemonic.                                       |

## Detailed Type Serialization

### `WalletCapability`

```rust
u8 // WalletCapability struct VERSION = 4
u32 // Rejection address length
UnifiedKeyStore // Stores spending or viewing keys
Vector<ReceiverSelection>
```

### `BlockData`

```rust
i32 // Block height
Vector<u8> // Block hash bytes
SaplingCommitmentTree // Sapling note commitment tree
u64 // BlockData struct version
Vector<u8> // Encoded compact block (ecb)
```

### `TxMap`

```rust
u64 // TxMap struct version
Vector<
    (
        TxId,
        TransactionRecord
    )
>
Option<WitnessTrees>
```

### `WalletOptions`

```rust
u64 // WalletOptions struct version
u8 // Memo download option (0 = No memos, 1 = Wallet memos, 2 = All memos)
Option<u32> // Transaction filter size
```

### `TreeState`

```rust
String // Network name: "main" or "test"
u64 // Block height
String // Block ID (hash)
u32 // Unix epoch time when the block was mined
String // Sapling commitment tree state
String // Orchard commitment tree state
```

### `WalletZecPriceInfo`

```rust
u64 // WalletZecPriceInfo struct version
Option<u64> // Last historical prices fetched at (timestamp)
u64 // Historical prices retry count
```

### `Mnemonic`

```rust
u32 // Account index
```

---

### `UnifiedKeyStore`

In-memory store for wallet spending or viewing keys.

```rust
u8 // UnifiedKeyStore struct VERSION = 0
if (has_spend_capability) {
    u8 // KEY_TYPE_SPEND = 2
    UnifiedSpendingKey // Unified spending key
} else if (has_view_capability) {
    u8 // KEY_TYPE_VIEW = 1
    UnifiedFullViewingKey // Unified full viewing key
} else if (empty_capability) {
    u8 // KEY_TYPE_EMPTY = 0
}
```

### `ReceiverSelection`

```rust

```

### `UnifiedSpendingKey`

### `UnifiedFullViewingKey`

### `SaplingCommitmentTree`

### `TxId`

### `TransactionRecord`

### `WitnessTrees`

## Changes

Version 30 changes:

- Added new wallet capability: Add read/write for rejection (ephemeral) addresses
