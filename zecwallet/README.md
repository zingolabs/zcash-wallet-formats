# Zecwallet

## Background information

Zecwallet uses a bespoke format for storing wallet data on disk.
The data is written and read linearly using Rust's `BufReader`/`BufWriter`.

The following snippet was taken from [here](https://github.com/adityapk00/zecwallet-light-cli/blob/bea9a26e3dcf6ed1dcc703848a942d343e38360c/bip39bug.md).

> ## Zecwallet-cli BIP39 derivation bug
>
> In v1.0 of zecwallet-cli, there was a bug that incorrectly derived HD wallet keys after the first key. That is, the first key, address was correct, but subsequent ones were not.
>
> The issue was that the 32-byte seed was directly being used to derive then subsequent addresses instead of the 64-byte pkdf2(seed). The issue affected both t and z addresses.
>
> Note that no funds are at risk. The issue is that, if in the future, you import the seed into a different wallet, you might not see all your addresses in the new wallet, so it's better to fix it now.
>
> ## Fix
>
> If you start a wallet that has this bug, you'll be notified.
> The bug can be automatically fixed by the wallet by running the `fixbip39bug` command. Just start `zecwallet-cli` and type `fixbip39bug`.
>
> If you have any funds in the incorrect addresses, they'll be sent to yourself, and the correct addresses re-derived.

Wallet storage is implemented in the following files:

- `lib/src/lighwallet/data.rs`
- `lib/src/lighwallet/keys.rs`
- `lib/src/lighwallet/utils.rs`
- `lib/src/lighwallet/wallet_txns.rs`
- `lib/src/lighwallet/walletokey.rs`
- `lib/src/lighwallet/wallettkey.rs`
- `lib/src/lighwallet/walletzkey.rs`
- `lib/src/lightclient.rs`
- `lib/src/lighwallet.rs`

The top-level functions used to write/read wallet data is in `lib/src/lightwallet.rs#439`.

## Schema (WIP)

The overall schema looks as follows:

| Keyname           | Value Type                                | Description             |
| ----------------- | ----------------------------------------- | ----------------------- |
| Version           | u64                                       |                         |
| Keys              | [`Keys`](#keys)                           |                         |
| Blocks            | Vector<[`BlockData`](#blockdata)>         |                         |
| Transactions      | [`WalletTxns`](#wallettxns)               |                         |
| Chain Name        | String                                    |                         |
| Wallet Options    | [`WalletOptions`](#walletoptions)         |                         |
| Birthday          | u64                                       |                         |
| Verified Tree     | Option<Vector<u8>>                        |                         |
| Price             |                                           | Price information.      |
| Orchard Witnesses | Option<BridgeTree<MerkleHashOrchard, 32>> | Orchard Witnesses Tree. |

## Types

### `String`

Strings are written as len + utf8.

```rust
u64 // length
bytes // utf8 bytes
```

### `Keys`

```rust
u64 // Version
u8 // Encrypted (1 = true, 0 = false)
[u8; 48] // Encrypted seed bytes
u8 // Nonce
[u8; 32] // Seed
Vector<WalletOKey> // Orchard keys
Vector<WalletZKey> // ZKeys (combination of HD keys derived from the seed, viewing keys and imported spending keys)
Vector<WalletTKey> // Transparent private keys
```

### `WalletOKey`

A struct that holds orchard private keys or viewing keys

### `WalletZKey`

A struct that holds z-address private keys or viewing keys

### `WalletTKey`

### `BlockData`

Contains the encoded block data and the block height.

```rust
i32 // height
Vector<u8> // Block hash
CommitmentTree::<Node>::empty() // WIP
u64 // BlockData struct version
Vector<u8> // Encoded block data (ecb) WIP: hex(CompactBlock), what's CompactBlock?
```

### `WalletTxns`

List of all transactions in a wallet.

```rust
u64 // WalletTxns struct version

// The hashmap, write a set of tuples. Store them sorted so that wallets are deterministically saved
Vector<
    TxId // Transaction id
    WalletTx // Transaction data
>
```

### `TxId`

### `WalletTx`

### `WalletOptions`

```rust
u64 // WalletOptions struct version
u8 // Memo download option (0 = No memos, 1 = Wallet memos, 2 = All memos)
i64 // Spam threshold
```

## Important Information

### Transparent Key Derivation

Include this paper: https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2023-012-envelope-expression.md
