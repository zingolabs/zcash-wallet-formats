# Zingo & Zingolib

## Background information

Zingo/Zingolib is a fork of [Zecwallet](../zecwallet/README.md) and, as a result, many structures are similar.
It uses a bespoke format for storing wallet data on disk.

The top-level functions used to write/read wallet data are in `zingolib/src/wallet/disk.rs#48`.

## Schema

The overall schema looks as follows:

| Keyname                             | Value                                       | Description                                             |
| ----------------------------------- | ------------------------------------------- | ------------------------------------------------------- |
| LightWallet Version                 | u64 = 30                                    |                                                         |
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

```

### `BlockData`

```rust

```

### `TxMap`

```rust

```

### `WalletOptions`

```rust

```

### `TreeState`

```rust

```

### `WalletZecPriceInfo`

```rust

```

### `Mnemonic`

```rust

```

## Changes

Version 30 changes:

- Added new wallet capability: Add read/write for rejection (ephemeral) addresses
