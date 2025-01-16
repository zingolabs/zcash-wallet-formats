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

More information in [the Zecwallet-CLI v1.1.0 release notes](https://github.com/adityapk00/zecwallet-light-cli/releases/tag/1.1.0).

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

The data stored comes from the `LightWallet` struct, and is written as follows:

| Keyname                             | Value Type                                | Description                 |
| ----------------------------------- | ----------------------------------------- | --------------------------- |
| Version                             | u64                                       | LightWallet struct version. |
| Keys                                | [`Keys`](#keys)                           | Wallet keys.                |
| Blocks                              | Vector<[`BlockData`](#blockdata)>         | Blocks.                     |
| Transactions                        | [`WalletTxns`](#wallettxns)               | Transactions.               |
| Chain Name                          | String                                    | Chain name.                 |
| Wallet Options                      | [`WalletOptions`](#walletoptions)         | Options.                    |
| <span id="birthday">Birthday</span> | u64                                       | Wallet birthday height.     |
| Verified Tree                       | Option<TreeState>                         | Commitment tree state.      |
| Price                               | WalletZecPriceInfo                        | Price information.          |
| Orchard Witnesses                   | Option<BridgeTree<MerkleHashOrchard, 32>> | Orchard Witnesses Tree.     |

## Encryption

Private keys are encrypted using the `secretbox` Rust crate, by getting the doublesha256 of the user's password and
a randomly generated nonce. The seal function, used to encrypt the private key,
is `crypto_secretbox_xsalsa20poly1305`, a particular combination of Salsa20 and Poly1305 specified in [Cryptography in NaCl](https://nacl.cr.yp.to/valid.html).
For more information, read https://cr.yp.to/highspeed/naclcrypto-20090310.pdf.

## Constants

```rust
SECRET_KEY_SIZE: u8 = 32 (0x20)
MERKLE_DEPTH: u8 = 32 (0x20)
SER_V1: u8 = 1
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
u64 // Keys struct version
u8 // Encrypted (1 = true, 0 = false)
[u8; 48] // Encrypted seed bytes
u8 // Nonce
[u8; 32] // Seed
Vector<WalletOKey> // Orchard keys
Vector<WalletZKey> // ZKeys (combination of HD keys derived from the seed, viewing keys and imported spending keys)
Vector<WalletTKey> // Transparent private keys
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

### `WalletOKey`

A struct that holds orchard private keys or viewing keys.

```rust
u64 // WalletOKey struct version
WalletOKeyType // keytype
u8 // Locked (1 = true, 0 = false)
Option<u32> // HD Key number. Only present if it is an HD key
orchard::FullViewingKey // Full viewing key
Option<orchard::SpendingKey> // Spending key

// Encrypted Spending Key
Option<Vector<u8>> // Output of secretbox::seal(secret_key, nonce, doublesha256(password)). Check `Encryption` for more information
Option<Vector<u8>> // Nonce
```

### `WalletZKey`

A struct that holds z-address private keys or viewing keys.

```rust
u64 // WalletZKey struct version
WalletZKeyType // keytype
u8 // Locked (1 = true, 0 = false)
Option<ExtendedSpendingKey> // Extended Spending key
ExtendedFullViewingKey // Extended Full Viewing key
Option<u32> // HD Key number. Only present if it is an HD key

// Encrypted Extended Spending Key
Option<Vector<u8>> // Output of secretbox::seal(secret_key, nonce, doublesha256(password)). Check `Encryption` for more information
Option<Vector<u8>> // Nonce
```

### `WalletTKey`

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

### `WalletZKeyType`

```rust
u32 // 0 = HD key, 1 = Imported Spending key, 2 = Imported Viewing Key
```

### `WalletOKeyType`

```rust
u32 // 0 = HD key, 1 = Imported Spending key, 2 = Imported Full Viewing Key
```

### `WalletTKeyType`

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
CommitmentTree::<Node>::empty() // Commitment tree. Serialized as: (Optional(empty), Optional(empty), vec[] (also empty))
u64 // BlockData struct version
Vector<u8> // Encoded compact block (ecb)
```

### `CompactBlock`

This is not a Rust type, but a Protocol Buffer type.

```rust
u32 // Proto version
u64 // Height
Vector<u8> // Hash
Vector<u8> // Previous hash
u32 // Unix epoch time when the block was mined
Vector<u8> // (hash, prevHash, and time) OR (full header)
Vector<CompactTx> // Zero or more compact transactions from this block
```

### `CompactTx`

This is not a Rust type, but a Protocol Buffer type.

```rust
u64 // Index within the full block
Vector<u8> // Transaction hash (ID), same as in block explorers
Option<u32> // Transaction fee (optional)
Vector<CompactSaplingSpend> // Sapling inputs
Vector<CompactSaplingOutput> // Sapling outputs
Vector<CompactOrchardAction> // Orchard actions
```

### `CompactSaplingSpend`

CompactSaplingSpend is a Sapling Spend Description as described in 7.3 of the Zcash protocol specification.

This is not a Rust type, but a Protocol Buffer type.

```rust
Vector<u8> // Nullifier (nf)
```

Output is a Sapling Output Description as described in section 7.4 of the Zcash protocol spec. Total size is 948.

### `CompactSaplingOutput`

This is not a Rust type, but a Protocol Buffer type.

```rust
Vector<u8> // Note commitment u-coordinate (cmu)
Vector<u8> // Ephemeral public key (epk)
Vector<u8> // First 52 bytes of ciphertext
```

### `CompactOrchardAction`

This is not a Rust type, but a Protocol Buffer type.

```rust
Vector<u8> // Nullifier of the input note (32 bytes)
Vector<u8> // x-coordinate of the note commitment for the output note (cmx, 32 bytes)
Vector<u8> // Encoding of an ephemeral Pallas public key (ephemeralKey, 32 bytes)
Vector<u8> // Note plaintext component of the encCiphertext field (ciphertext, 52 bytes)
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

V5 transaction data.

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

### `ExtendedSpendingKey`

```rust
u8 // Depth
[u8; 4] // Parent FVK tag
u32 // Child index
[u8; 32] // Chain code
sapling::ExpandedSpendingKey // [u8; 96]. Spending key
[u8; 32] // Diversifier key
```

### `sapling::ExpandedSpendingKey`

```rust
[u64; 4] // ask
[u64; 4] // nsk
[u8; 32] // ovk
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
pallas::Base // Base field of the Pallas and iso-Pallas curves
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

### `orchard::SpendingKey`

```rust
[u8; 32] // sk
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
pallas::Base
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

### `pallas::Base`

```rust
[u8; 32]
```

### `WalletZecPriceInfo`

```rust
u64 // WalletZecPriceInfo struct version
Option<u64> // Last historical prices fetched at (timestamp)
u64 // Historical prices retry count
```

### `BridgeTree<H = MerkleHashOrchard, Depth = MERKLE_DEPTH>`

```rust
u64 // BridgeTree struct version

Vector<MerkleBridge> // Prior bridges

Option<MerkleBridge> // Current bridge

// Witnessed indices. A map from positions for which we wish to be able to compute an authentication path to index in the bridges vector.
Vector<
    u64 // Position
    u64 // Index
>

Vector<Checkpoint> // Checkpoints
u64 // Max checkpoints
```

### `MerkleBridge`

```rust
SER_V1

Option<u64> // Prior position. The position of the final leaf in the frontier of the bridge that this bridge is the successor of.

// Bridge auth fragments
Vector<
    u64 // Position
    AuthFragment
>

NonEmptyFrontier<MerkleHashOrchard>
```

### `AuthFragment`

```rust
u64 // Position
u64 // Altitudes observed
Vector<MerkleHashOrchard>
```

### `MerkleHashOrchard`

```rust
pallas::Base // Hash
```

### `NonEmptyFrontier<H>`

```rust
u64 // Position

if (leaf is left) {
    H // Left hash
    Optional<None> // Right hash
} else {
    H // Left hash
    Optional<H> // Right hash
}

Vector<H> // Frontier ommers
```

### `Checkpoint`

```rust
u64 // Bridge length
u8 // Is witnessed (1 = true, 0 = false)
Vector<u64> // Witnessed positions

// The set of previously-witnessed positions that have had their witnesses removed during the period that this checkpoint is the current checkpoint
Vector<
    u64 // Position
    u64 // Index
>
```

## Important Information

### Transparent Key Derivation

Unlike other wallets, Zecwallet always derives the scope (change) as `0` (external).
