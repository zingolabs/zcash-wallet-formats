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

## Schema

Note: all numeric types are written as little endian.

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

## Constants

```rust
SECRET_KEY_SIZE = 32 (0x20)
```

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

Private keys are encrypted using the `secretbox` Rust crate, by getting the doublesha256 of the user's password and
a randomly generated nonce. The seal function, used to encrypt the private key,
is `crypto_secretbox_xsalsa20poly1305`, a particular combination of Salsa20 and Poly1305 specified in [Cryptography in NaCl](https://nacl.cr.yp.to/valid.html).
For more information, read https://cr.yp.to/highspeed/naclcrypto-20090310.pdf.

```rust
u64 // WalletTKey struct version
WalletTKeyType // keytype
u8 // Locked (1 = true, 0 = false)
Option<SecretKey> // Secret key
String // Address
Option<u32> // HD Key number. Only present if it is an HD key
Option<Vector<u8>> // Encrypted Secret Key. Output of secretbox::seal(secret_key, nonce, doublesha256(password))
Option<Vector<u8>> // Nonce
```

### WalletTKeyType

```rust
u32 // 0 = HD key, 1 = imported key
```

### `SecretKey`

```rust
[u8; SECRET_KEY_SIZE] // A secp256k1 secret key
```

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

```rust
[u8; 32] // Transaction id
```

### `WalletTx`

```rust
u64 // WalletTx struct version
u32 // Block height
u8 // Unconfirmed (1 = true, 0 = false)
u64 // Datetime
TxId // Transaction id

// Sapling notes
Vector<
    SaplingNoteData
>

// UTXOs
Vector<
    Utxo
>

u64 // Total Orchard value spent
u64 // Total Sapling value spent
u64 // Total Transparent value spent

// Outgoing transaction metadata
Vector<OutgoingTxMetadata>

u8 // Full transaction scanned (1 = true, 0 = false)
Option<f64> // Zec price. Writes a IEEE754 double-precision (8 bytes) floating point number.

// Sapling spent nullifiers
Vector<sapling::Nullifier>

// Orchard notes
Vector<OrchardNoteData>

// Orchard spent nullifiers
Vector<orchard::Nullifier>
```

### `SaplingNoteData`

```rust
u64 // SaplingNoteData struct version
ExtendedFullViewingKey // Extended full viewing key
```

### `ExtendedFullViewingKey`

```rust
u8 // Key depth
[u8; 4] // Parent FVK tag
u32 // Child index
[u8; 32] // Chain code
sapling::FullViewingKey // [u8; 96]. Full viewing key
[u8; 32] // Diversifier key
```

### `sapling::FullViewingKey`

```rust
JubjubSubgroupPoint // [u8; 32]. ak
NullifierDerivingKey // [u8; 32]. nk
OutgoingViewingKey // ovk

```

### `sapling::ViewingKey`

```rust
jubjub::SubgroupPoint // ak
sapling::NullifierDerivingKey // nk
OutgoingViewingKey // ovk
```

### `sapling::NullifierDerivingKey`

```rust
jubjub::SubgroupPoint
```

### `OutgoingViewingKey`

```rust
[u8; 32] // ovk
```

### `Utxo`

```rust
u64 // Utxo struct version
u32 // Address length
String // Address
TxId // Transaction id
u64 // Output index
u64 // Value
i32 // Height

// Script
Vector<u8>

Option<TxId> // Spent
Option<i32> // Spent at height

// Unconfirmed spent
Option<
    TxId // Transaction id
    u32 // Height
>
```

### `WalletOptions`

```rust
u64 // WalletOptions struct version
u8 // Memo download option (0 = No memos, 1 = Wallet memos, 2 = All memos)
i64 // Spam threshold
```

### `OutgoingTxMetadata`

```rust
u64 // Address length
String // Address
u64 // Value
MemoBytes // Memo serialized per ZIP 302
```

### `MemoBytes`

```rust
[u8; 512] // Memo
```

### `sapling::Nullifier`

```rust
[u8; 32]
```

### `orchard::Nullifier`

The base field of the Pallas and iso-Pallas curves, used to represent a
unique nullifier for a note.

```rust
[u8; 32] // Base field of the Pallas and iso-Pallas curves
```

### `OrchardNoteData`

Note that we don't write the unconfirmed_spent field, because if the wallet is restarted,
we don't want to be beholden to any expired txns

```rust
u64 // OrchardNoteData struct version
orchard::FullViewingKey // Full viewing key

orchard::Address // Recipient
u64 // Note value
orchard::Nullifier // Note rho
[u8; 32] // Note rseed (random seed)

Option<u64> // Witness position

// Spent
Option<
    TxId // Transaction id
    u32 // Height
>

// Unconfirmed spent
Option<
    TxId // Transaction id
    u32 // Height
>

Option<MemoBytes> // Memo

u8 // Is change (1 = true, 0 = false)
u8 // Have spending key (1 = true, 0 = false)
```

### `orchard::Address`

```rust
[u8; 11] // Diversifier
[u8; 32] // Diversified Transmission Key
```

### `orchard::FullViewingKey`

Zcash Protocol Spec § 5.6.4.4: Orchard Raw Full Viewing Keys.
Result is of length [u8; 96]

```rust
orchard::SpendValidatingKey // ak
orchard::NullifierDerivingKey // nk
orchard::CommitIvkRandomness // rivk
```

### `orchard::SpendValidatingKey`

A key used to validate spend authorization signatures.
The point repr is the same as I2LEOSP of its x-coordinate.
[Orchard Key Components](https://zips.z.cash/protocol/nu5.pdf#orchardkeycomponents).

```rust
[u8; 32] // redpallas::VerificationKey<SpendAuth>
```

### `orchard::NullifierDerivingKey`

A key used to derive Nullifiers from Notes.
[Orchard Key Components](https://zips.z.cash/protocol/nu5.pdf#orchardkeycomponents).

```rust
[u8; 32] // pallas::Base
```

### `orchard::CommitIvkRandomness`

[Orchard Key Components](https://zips.z.cash/protocol/nu5.pdf#orchardkeycomponents).

```rust
[u8; 32] // pallas::Scalar
```

### `jubjub::SubgroupPoint`

```rust
[u8; 32]
```

## Important Information

### Transparent Key Derivation

Include this paper: https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2023-012-envelope-expression.md
