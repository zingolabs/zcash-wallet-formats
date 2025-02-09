# Zcashd

## Important Information

[ZIP-400](https://zips.z.cash/zip-0400) documents the schema used for zcashd `v3.0.0-rc1`. Since then, the format has changed a bit.
[zips#964](https://github.com/zcash/zips/issues/964) also tracks ZIP-400's update.

There's also a document explaining what data / state needs to be migrated from `wallet.dat` to a future full node wallet [here](./migration-data.md).
That document is more targeted torwards [zcash#3873](https://github.com/zcash/zcash/issues/6873).

## Background

> The following text is taken from [this wallet guide for exchanges](https://hackmd.io/@daira/rJVEmOCkh).
> Read through to learn more about changes accross versions.

The `zcashd` internal wallet was, as with the rest of zcashd, forked from Bitcoin code in May 2015.
The original design of the wallet treated all transparent addresses in the wallet as receiving funds into
a single "bucket of money" from which spends could be made. In this original design, individual addresses were not
treated as having individual, distinguishable balances (even though such per-address balances were representable
at the protocol layer). This single "bucket" of transparent funds was treated as though it was associated with a single spending authority,
even though actually spending funds from this pool might involve creating signatures with multiple distinct transparent spending keys.
The RPC method `getnewaddress` produced new keys internally via derivation from system randomness, and so these keys had to
be backed up independently even though the wallet did not make distinctions between them visible to the user of `zcashd`.
Similarly, the `getbalance` RPC method treated funds spendable by these independent keys uniformly, as did the other Bitcoin-inherited methods.

When `zcashd` introduced the Sprout, and later the Sapling protocols, it diverged from this original design
by treating each Sprout and Sapling address in the wallet as being associated with an independent spending authority
tied to the address. With Sprout, keys continued to be derived from system randomness, but Sapling introduced a new hierarchical
derivation mechanism, similar to that defined in BIPs 32, 43 and 44. Instead of deriving keys from randomness,
Sapling keys were all derived from a single binary seed value.

As part of introducing the Sprout transfer protocol `zcashd` introduced a few new RPC methods, most
importantly `z_getbalance` and `z_sendmany` which reflected the choice to treat separate addresses
as holding independent balances, and these semantics were retained when the Sapling protocol was added.
However, in the process, a conceptual error was introduced.

With the introduction of `z_getbalance` and `z_sendmany`, it became possible for users to begin treating separate transparent addresses
in the wallet as having independent balances, even though the Bitcoin-derived RPC methods treated those balances as simply being
part of a larger undifferentiated pool of funds. Over the intervening years, users have come to depend upon this inadvertent semantic
change.

## Key derivation

`zcashd` version 4.6.0 and later uses this path to derive "legacy" Sapling addresses from a mnemonic seed phrase under account `0x7FFFFFFF`,
using hardened derivation for `address_index`:

```
m/purpose'/coin_type'/account'/address_index
```

The following text is taken from [this Github issue](https://github.com/zcash/zips/issues/675).

When Sapling was released, `zcashd` implemented HD derivation of Sapling addresses in a fashion that was inconsistent with HD derivation according to BIP 44.
In version 4.7.0 `zcashd` introduced HD derivation from a mnemonic seed according to BIP 32 and BIP 44, with a nonstandard accommodation in the generation
of the mnemonic seed to make it possible to also reproduce previously derived Sapling keys. This accommodation needs to be documented,
along with the process for correct discovery of such previously-derived Sapling keys.

In addition, in order to continue allow `zcashd`'s legacy transparent APIs such as `getnewaddress` and `z_getnewaddress` to continue to function, `zcashd` introduced
the idea of the `ZCASH_LEGACY_ACCOUNT` constant for use in address derivation consistent with the previous semantics of those methods.
Derivation of keys under `ZCASH_LEGACY_ACCOUNT` is also nonstandard with respect to BIP 32 and BIP 44, and so needs to be properly documented here in order
to make it possible for other wallet implementations to correctly rediscover funds controlled by keys derived using this mechanism.

Note that the primary derivation path is defined in [ZIP-32](https://zips.z.cash/zip-0032).

## Serialization framework overview

Bitcoind (and zcashd, by extension) employs a custom serialization framework to encode both `Key` and `Value` fields.
This framework handles type-specific serialization, compact sizes, optional fields, and more.
See the [serialization reference](#serialization-reference) for details on how each type is serialized.
Also check out [the Bitcoin Core Onboarding's wallet database section](https://bitcoincore.academy/wallet-database.html).

Data is stored in `dat` files, which are implemented as a BerkeleyDB[^1]. Each entry is serialized using the following structure:

```
<keyname_length><keyname><key>
<value>
```

Where:

- `<keyname_length>` is a byte representing the length of `<keyname>`.
- `<keyname>` is an ASCII encoded string of the length `<keyname_length>` and `<key>` the binary data.
- `<key>` is the output of the serialization of each `Key`.
- `<value>` is the output of the serialization of each `Value`.

Each key and value has an associated C++ class (and sometimes a Rust struct, depending on the version) from [zcashd](https://github.com/zcash/zcash).
Check **[this table](#serialization-reference)** to learn more about how each class is serialized.

## Serialization of Key/Value pairs by version

What value/pair is serialized is taken from [this walletdb.cpp file](https://github.com/zcash/zcash/blob/master/src/wallet/walletdb.cpp).

The following key-values can be found: the property names in bold mean only one instance of this type can exist in the entire database,
while the others, suffixed by '\*' can have multiple instances. `key` and `value` columns of the table contain the types that the stored data is representing.

### v3.0.0-rc1

Taken from: https://zips.z.cash/zip-0400.
Open in fullscreen, as this table is too wide.

| `keyname`            | `key`                                                               | `value`                                                                                                                                                                           | Description                                                    |
| -------------------- | ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| acc\*                | [`string`](#string) (account name)                                  | [`CAccount`](#CAccount)                                                                                                                                                           | DISABLED. Account information.                                 |
| acentry\*            | `string` (account name) + [`uint64_t`](#uint64_t) (counter)         | [`CAccountingEntry`](#CAccountingEntry)                                                                                                                                           | DISABLED. Account entry. Tracks internal transfers.            |
| **bestblock**        | -                                                                   | [`CBlockLocator`](#CBlockLocator)                                                                                                                                                 | The current best block of the blockchain.                      |
| **chdseed**          | [`uint256`](#uint256) (seed fingerprint)                            | [`vector`](#vector)[`<unsigned char>`](#unsigned_char) (see [Encryption](#encryption))                                                                                            | Encrypted HD seed.                                             |
| ckey\*               | [`CPubKey`](#CPubKey)                                               | `vector<unsigned char>` (see [Encryption](#encryption))                                                                                                                           | Transparent pubkey and encrypted private key.                  |
| csapzkey\*           | [`libzcash::SaplingIncomingViewingKey`](#SaplingIncomingViewingKey) | [`libzcash::SaplingExtendedFullViewingKey`](#SaplingExtendedFullViewingKey) (extended full viewing key) + `vector<unsigned char>` (crypted secret, see [Encryption](#encryption)) | Sapling pubkey and encrypted private key.                      |
| cscript\*            | [`uint160`](#uint160)                                               | [`CScriptBase`](#CScriptBase)                                                                                                                                                     | Serialized script, used inside transaction inputs and outputs. |
| czkey\*              | [`libzcash::SproutPaymentAddress`](#SproutPaymentAddress)           | `uint256` + `vector<unsigned char>`                                                                                                                                               | Encrypted Sprout pubkey and private key.                       |
| **defaultkey**       | -                                                                   | `CPubKey`                                                                                                                                                                         | Default Transparent key.                                       |
| destdata\*           | `string` (address) + `string` (key)                                 | `string` (value)                                                                                                                                                                  | Adds destination data tuple to the store.                      |
| **hdchain**          | -                                                                   | [`CHDChainV3`](#CHDChainV3)                                                                                                                                                       | Hierarchical Deterministic chain code, derived from seed.      |
| hdseed\*             | `uint256` (BLAKE2b hash)                                            | [`RawHDSeed`](#RawHDSeed)                                                                                                                                                         | Hierarchical Deterministic seed.[^2]                           |
| key\*                | `CPubKey`                                                           | [`CPrivKey`](#CPrivKey) + HASH256(`CPubKey` + `CPrivKey`)                                                                                                                         | Transparent pubkey and privkey.                                |
| keymeta\*            | `CPubKey`                                                           | [`CKeyMetadata`](#CKeyMetadata)                                                                                                                                                   | Transparent key metadata.                                      |
| **minversion**       | -                                                                   | [`int`](#int) (check [wallet versions](#wallet-versions))                                                                                                                         | Wallet required minimal version.                               |
| **mkey**             | [`unsigned int`](#unsigned_int)                                     | [`CMasterKey`](#CMasterKey)                                                                                                                                                       | Master key, used to encrypt public and private keys of the db. |
| name\*               | `string` (address)                                                  | `string` (name)                                                                                                                                                                   | Name of an address to insert in the address book.              |
| **orderposnext**     | -                                                                   | [`int64_t`](#int64_t)                                                                                                                                                             | Index of next tx.                                              |
| pool\*               | `int64_t`                                                           | [`CKeyPool`](#CKeyPool)                                                                                                                                                           | An address look-ahead pool.[^7]                                |
| purpose\*            | `string` (address)                                                  | `string` (purpose)                                                                                                                                                                | Short description or identifier of an address.                 |
| sapzaddr\*           | [`libzcash::SaplingPaymentAddress`](#SaplingPaymentAddress)         | `libzcash::SaplingIncomingViewingKey`                                                                                                                                             | Sapling z-addr Incoming Viewing key and address.               |
| sapextfvk\*          | `libzcash::SaplingExtendedFullViewingKey`                           | [`char`](#char) = '1'                                                                                                                                                             | Sapling Extended Full Viewing Key.                             |
| sapzkey\*            | `libzcash::SaplingIncomingViewingKey`                               | [`libzcash::SaplingExtendedSpendingKey`](#SaplingExtendedSpendingKey)                                                                                                             | Sapling Incoming Viewing Key and Extended Spending Key.        |
| tx\*                 | `uint256` (hash)                                                    | [`CWalletTx`](#CWalletTxTable)                                                                                                                                                    | Store all transactions that are related to wallet.             |
| **version**          | -                                                                   | `int` (check [wallet versions](#wallet-versions))                                                                                                                                 | The `CLIENT_VERSION` from `clientversion.h`.                   |
| vkey\*               | [`libzcash::SproutViewingKey`](#SproutViewingKey)                   | `char` = '1'                                                                                                                                                                      | Sprout Viewing Keys.                                           |
| watchs\*             | `CScriptBase`                                                       | `char` = '1'                                                                                                                                                                      | Watch-only t-addresses.                                        |
| **witnesscachesize** | -                                                                   | `int64_t` (witness cache size)                                                                                                                                                    | Shielded Note Witness cache size.                              |
| wkey\*               | -                                                                   | -                                                                                                                                                                                 | Wallet key. No longer used                                     |
| zkey\*               | `libzcash::SproutPaymentAddress`                                    | [`libzcash::SproutSpendingKey`](#SproutSpendingKey)                                                                                                                               | Sprout Payment Address and Spending Key.                       |
| zkeymeta\*           | `libzcash::SproutPaymentAddress`                                    | `CKeyMetadata`                                                                                                                                                                    | Sprout Payment Address and key metadata.                       |

#### Notes

The 'Account' API, which included both `acc` and `acentry` and were inherited from Bitcoin Core, has been disabled since the launch of Zcash. and finally removed in zcashd [v4.5.0](#v450).
Read the [zcashd v4.5.0 release notes](https://github.com/zcash/zcash/releases/tag/v4.5.0)
and [this bitcoin-core v0.17.0 release notes](https://github.com/bitcoin/bitcoin/blob/master/doc/release-notes/release-notes-0.17.0.md#label-and-account-apis-for-wallet)
for more information.

### v4.0.0

No changes to storage format since v3.0.0

Check out the full diff [here](./DIFF.md#v4)

### v4.5.0

#### Removed Fields:

| `keyname`   | `key`                     | `value`                | Description |
| ----------- | ------------------------- | ---------------------- | ----------- |
| ~~acc~~     | ~~`string`~~              | ~~`CAccount`~~         | -           |
| ~~acentry~~ | ~~`string` + `uint64_t`~~ | ~~`CAccountingEntry`~~ | -           |

### v5.0.0

#### Added and Removed Fields:

| `keyname`                        | `key`                                                                           | `value`                                                                                                      | Description                       |
| -------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | --------------------------------- |
| ~~hdseed~~                       | ~~`uint256`~~                                                                   | ~~`RawHDSeed`~~                                                                                              | -                                 |
| ~~chdseed~~                      | ~~`uint256`~~                                                                   | ~~`vector<unsigned char>`~~                                                                                  | -                                 |
| **networkinfo**                  | -                                                                               | [`pair`](#pair) `<string = 'Zcash', string (network identifier)>`                                            | Network identifier.               |
| **orchard_note_commitment_tree** | -                                                                               | [`OrchardWalletNoteCommitmentTreeWriter`](#OrchardWalletNoteCommitmentTreeWriterTable)                       | Orchard note commitment tree.     |
| unifiedaccount\*                 | [`ZcashdUnifiedAccountMetadata`](#ZcashdUnifiedAccountMetadata)                 | 0x00                                                                                                         | Unified account information.      |
| unifiedfvk\*                     | [`libzcash::UFVKId`](#UFVKId)                                                   | [`libzcash::UnifiedFullViewingKey::Encode(string, UnifiedFullViewingKeyPtr)`](#encode) as string             | Encoded unified FVK.              |
| unifiedaddrmeta\*                | [`ZcashdUnifiedAddressMetadata`](#ZcashdUnifiedAddressMetadata)                 | 0x00                                                                                                         | Unified address metadata.         |
| **mnemonicphrase**               | `uint256` (seed fingerprint)                                                    | [`MnemonicSeed`](#MnemonicSeed) (seed)                                                                       | Mnemonic phrase.                  |
| **cmnemonicphrase**              | `uint256`                                                                       | `std::vector<unsigned char>` (encrypted mnemonic seed. Check [Encryption](#encryption) for more information) | Encrypted mnemonic phrase.        |
| **mnemonichdchain**              | -                                                                               | [`CHDChainV5`](#CHDChainV5)                                                                                  | HD chain metadata.                |
| recipientmapping\*               | `pair<uint256,` [`CSerializeRecipientAddress`](#CSerializeRecipientAddress) `>` | `string` (recipient UA)                                                                                      | Maps transaction to recipient UA. |

Check out the full diff [here](./DIFF.md#v5)

### v6.0.0

#### Added Fields:

| `keyname`              | `key` | `value`                 | Description                                                                                                                  |
| ---------------------- | ----- | ----------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **bestblock**          | -     | `CBlockLocator` (empty) | The current best block of the blockchain. Empty block locator so versions that require a merkle branch automatically rescan. |
| **bestblock_nomerkle** | -     | `CBlockLocator`         | A place in the block chain. If another node doesn't have the same branch, it can find a recent common trunk.                 |

Check out the full diff [here](./DIFF.md#v6)

## Serialization reference

### Common data types

Note on signed integer serialization: All signed integers are serialized using **two's complement** representation.
This format is standard for representing signed numbers in binary and is compatible with the little-endian encoding used throughout the bitcoind/zcashd serialization framework.

| Data Type                                                             | Description                                                                                                                       | Serialized as                                                                                                                       |
| --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| <span id="int">`int`</span>                                           | 32-bit signed integer.                                                                                                            | Little-endian, 4 bytes                                                                                                              |
| <span id="unsigned_int">`unsigned int`</span>                         | 32-bit unsigned integer.                                                                                                          | Little-endian, 4 bytes                                                                                                              |
| <span id="int32_t">`int32_t`</span>                                   | 32-bit signed integer.                                                                                                            | Little-endian, 4 bytes                                                                                                              |
| <span id="int64_t">`int64_t`</span>                                   | 64-bit signed integer.                                                                                                            | Little-endian, 8 bytes                                                                                                              |
| <span id="uint8_t">`uint8_t`</span>                                   | 8-bit unsigned integer.                                                                                                           | 1 byte                                                                                                                              |
| <span id="uint32_t">`uint32_t`</span>                                 | 32-bit unsigned integer.                                                                                                          | Little-endian, 4 bytes                                                                                                              |
| <span id="uint64_t">`uint64_t`</span>                                 | 64-bit unsigned integer.                                                                                                          | Little-endian, 8 bytes                                                                                                              |
| <span id="uint160">`uint160`</span>                                   | An opaque blob of 160 bits without integer operations.                                                                            | Little-endian, 20 bytes                                                                                                             |
| <span id="uint256">`uint256`</span>                                   | An opaque blob of 256 bits without integer operations.                                                                            | Little-endian, 32 bytes                                                                                                             |
| <span id="uint252">`uint252`</span>                                   | Wrapper of uint256 with guarantee that first four bits are zero.                                                                  | Little-endian, 32 bytes                                                                                                             |
| <span id="string">`string`</span>                                     | UTF-8 encoded string.                                                                                                             | 1 byte (length) + bytes of the string                                                                                               |
| <span id="unsigned_char">`unsigned char`</span>                       | Byte or octet.                                                                                                                    | 1 byte                                                                                                                              |
| <span id="bool">`bool`</span>                                         | Boolean value.                                                                                                                    | 1 byte (0x00 = false, 0x01 = true)                                                                                                  |
| <span id="pair">`pair<K, T>`</span>                                   | A pair of 2 elements of types `K` and `T`.                                                                                        | `T` and `K` in sequential order.                                                                                                    |
| <span id="CCompactSize">`CCompactSize`</span>                         | A variable-length encoding for collection sizes.                                                                                  | 1 byte for sizes < 253, 3 bytes for sizes between 253 and 65535, 5 bytes for sizes between 65536 and 4GB, 9 bytes for larger sizes. |
| <span id="array">`array<T, N>`</span>                                 | An array of `N` elements of type `T`.                                                                                             | Serialized elements `T` in order. `N` is not serialized, as the array is always the same length.                                    |
| <span id="vector">`vector<T>`</span>                                  | Dynamic array of elements of type `T`.                                                                                            | [`CCompactSize`](#CCompactSize) (number of elements) + serialized elements `T` in order.                                            |
| <span id="prevector">`prevector<N, T>`</span>                         | Dynamic array of elements of type `T`, optimized for fixed size.                                                                  | `CCompactSize` (number of elements) + serialized elements `T` in order.                                                             |
| <span id="map">`map<K, V>`</span>                                     | A map of key-value pairs.                                                                                                         | `CCompactSize` (number of key-value pairs) + serialized keys `K` and values `V` in order.                                           |
| <span id="optional">`optional<T>`</span>                              | A container that optionally holds a value, serialized with a presence flag followed by the value if present.                      | 1 byte (discriminant: 0x00 = absent, 0x01 = present) + serialized value `T` if present.                                             |
| <span id="list">`list<T>`</span>                                      | Dynamically sized linked list of elements of type `T`.                                                                            | [`CCompactSize`](#CCompactSize) (number of elements) + serialized elements `T` in order.                                            |
| <span id="diversifier_t">`libzcash::diversifier_t`</span>             | An 11-byte value used to select a valid Jubjub base point, which is then used to derive a diversified Sapling or Orchard address. | [`array`](#array) `<unsigned char>[11]`                                                                                             |
| <span id="diversifier_index_t">`libzcash::diversifier_index_t`</span> | An opaque blob of 88 bits, representing a diversifier index.                                                                      | `array<unsigned char>[11]`                                                                                                          |
| <span id="CAmount">`CAmount`</span>                                   | A wrapper for int64_t that represents monetary values in zatoshis.                                                                | `int64_t`                                                                                                                           |
| <span id="joinsplit_sig_t">`joinsplit_sig_t`</span>                   | The JoinSplit signature, an Ed25519 digital signature.                                                                            | `array<unsigned char>[64]`                                                                                                          |
| <span id="binding_sig_t">`binding_sig_t`</span>                       | A Sapling binding signature (a RedJubjub signature) that enforces consistency between Spend descriptions and Output descriptions. | `array<unsigned char>[64]`                                                                                                          |
| <span id="mapSproutNoteData_t">`mapSproutNoteData_t`</span>           | Mapping of (Sprout) note outpoints to note data.                                                                                  | [`map`](#map)`<`[`JSOutPoint`](#JSOutPoint)`,`[`SproutNoteData`](#SproutNoteData)`>`                                                |
| <span id="mapSaplingNoteData_t">`mapSaplingNoteData_t`</span>         | Mapping of (Sapling) note outpoints to note data.                                                                                 | [`map`](#map)`<`[`SaplingOutPoint`](#SaplingOutPoint)`,`[`SaplingNoteData`](#SaplingNoteData)`>`                                    |
| <span id="spend_auth_sig_t">`spend_auth_sig_t`</span>                 | Signature authorizing a spend.                                                                                                    | `array<unsigned char>[64]`                                                                                                          |

### Classes

| Class                                                                                                | Description                                                                                                          | Serialized as                                                                                                                                                                                                                                                                              |
| ---------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| <span id="CAccount">`CAccount`</span>                                                                | Account information.                                                                                                 | `CPubKey` (public key)                                                                                                                                                                                                                                                                     |
| <span id="CPubKey">`CPubKey`</span>                                                                  | Public key.                                                                                                          | `CCompactSize` (public key length) + `unsigned char[33 \| 65]`(public key in compressed/uncompressed format)                                                                                                                                                                               |
| <span id="CPrivKey">`CPrivKey`</span>                                                                | Uncompressed private key, encoded as a DER ECPrivateKey type from section C.4 of SEC 1.[^3] [^10]                    | `vector<unsigned char>[214 \| 279]` (private key)                                                                                                                                                                                                                                          |
| <span id="CKeyMetadata">`CKeyMetadata`</span>                                                        | Key metadata.                                                                                                        | `int64_t` (creation time as unix timestamp. 0 if unknown) + `string` (optional HD/zip32 keypath[^2]) + `uint256` (seed fingerprint)                                                                                                                                                        |
| <span id="CMasterKey">`CMasterKey`</span>                                                            | Master key for wallet encryption. Encrypted using AES-256-CBC.[^4]                                                   | `vector<unsigned char>[32]` (encryption key) + `unsigned char[8]` (salt) + `unsigned int` (0 = EVP_sha512[^5] \| 1 = scrypt[^6]) + `unsigned int` (derivation iterations) + `vector<unsigned char> (extra parameters)`                                                                     |
| <span id="CAccountingEntry">`CAccountingEntry`</span>                                                | Tracks an internal account transfer.                                                                                 | `int64_t` (credit or debit in zatoshis) + `int64_t` (unix timestamp) + `string` (other_account) + '\0' + [`map`](#map)`<string, string>` (metadata, includes `n` to indicate position) + `map`<`string`, `string`> (extra information)                                                     |
| <span id="CBlockLocator">`CBlockLocator`</span>                                                      | A list of current best blocks.                                                                                       | `vector<uint256>` (vector of block hashes)                                                                                                                                                                                                                                                 |
| <span id="CKeyPool">`CKeyPool`</span>                                                                | Pre-generated public key for receiving funds or change.                                                              | `int64_t` (creation time as unix timestamp) + `CPubKey` (public key)                                                                                                                                                                                                                       |
| <span id="CHDChainV3">`CHDChainV3`</span>                                                            | HD chain metadata.                                                                                                   | `int` (nVersion) + `uint256` (seed fingerprint) + `int64_t` (nTime) + [`uint32_t`](#uint32_t) (accountCounter)                                                                                                                                                                             |
| <span id="CHDChainV5">`CHDChainV5`</span>                                                            | HD chain metadata.                                                                                                   | `int` (nVersion = '1') + `uint256` (seed fingerprint) + `int64_t` (nCreateTime) + [`uint32_t`](#uint32_t) (accountCounter) + `uint32_t` (legacyTKeyExternalCounter) + `uint32_t` (legacyTKeyInternalCounter) + `uint32_t` (legacySaplingKeyCounter) + `bool` (mnemonicSeedBackupConfirmed) |
| <span id="RawHDSeed">`RawHDSeed`</span>                                                              | Hierarchical Deterministic seed.[^2]                                                                                 | `vector<unsigned char>[32]` (raw HD seed, min length 32)                                                                                                                                                                                                                                   |
| <span id="COutPoint">`COutPoint`</span>                                                              | A combination of a transaction hash and an index n into its vout.                                                    | `uint256` (hash) + `uint32_t` (index)                                                                                                                                                                                                                                                      |
| <span id="SaplingOutPoint">`SaplingOutPoint`</span>                                                  | A combination of a transaction hash and an index n into its sapling output description (vShieldedOutput).            | `uint256` (hash) + `uint32_t` (index)                                                                                                                                                                                                                                                      |
| <span id="CTxIn">`CTxIn`</span>                                                                      | An input of a transaction.                                                                                           | [`COutPoint`](#COutPoint) (previous tx output) + `CScriptBase` (script signature) + `uint32_t` (sequence number)                                                                                                                                                                           |
| <span id="CTxOut">`CTxOut`</span>                                                                    | An output of a transaction. Contains the public key that the next input must sign to claim it.                       | `int64_t` (value) + `CScriptBase` (scriptPubKey)                                                                                                                                                                                                                                           |
| <span id="JSOutPoint">`JSOutPoint`</span>                                                            | JoinSplit note outpoint.                                                                                             | `uint256` (hash) + `uint64_t` (index into CTransaction.vJoinSplit) + `uint8_t` (index into JSDescription fields)                                                                                                                                                                           |
| <span id="SproutNoteData">`SproutNoteData`</span>                                                    | Data for a Sprout note.                                                                                              | `libzcash::SproutPaymentAddress` (address) + `optional<uint256>` (nullifier) + `list<SproutWitness>` (witnesses) + `int` (witnessHeight)                                                                                                                                                   |
| <span id="IncrementalMerkleTree">`IncrementalMerkleTree<Depth, Hash>`</span>                         | Incremental Merkle tree with `Depth` levels, using `Hash` as the hash function.                                      | `optional<Hash>` (left) + `optional<Hash>` (right) + `vector<optional<Hash>>` (parents)                                                                                                                                                                                                    |
| <span id="IncrementalWitness">`IncrementalWitness<Depth, Hash>`</span>                               | Incremental Merkle witness.                                                                                          | `IncrementalMerkleTree<Depth, Hash>` (tree) + `vector<Hash>` (filled/hashed nodes) + `optional<IncrementalMerkleTree<Depth, Hash>>` (cursor)                                                                                                                                               |
| <span id="PedersenHash">`libzcash::PedersenHash`</span>                                              | Pedersen hash.                                                                                                       | `uint256` (hash)                                                                                                                                                                                                                                                                           |
| <span id="SaplingWitness">`SaplingWitness`</span>                                                    | An incremental witness that tracks the inclusion of a note commitment in the Sapling Merkle tree.                    | `IncrementalWitness<32, libzcash::PedersenHash>`                                                                                                                                                                                                                                           |
| <span id="SaplingNoteData">`SaplingNoteData`</span>                                                  | Data for a Sapling note.                                                                                             | `libzcash::SaplingIncomingViewingKey` (ivk) + `optional<uint256>` (nullifier) + `list<SaplingWitness>` (witnesses) + `int` (witnessHeight)                                                                                                                                                 |
| <span id="CompressedG1">`CompressedG1`</span>                                                        | Compressed point in G1.                                                                                              | `unsigned char` (0x02 or 0x02 \| 1) + `uint256` (x)                                                                                                                                                                                                                                        |
| <span id="CompressedG2">`CompressedG2`</span>                                                        | Compressed point in G2.                                                                                              | `unsigned char` (0x0a or 0x0a \| 1) + `uint256` (x)                                                                                                                                                                                                                                        |
| <span id="GrothProof">`libzcash::GrothProof`</span>                                                  | Groth proof.                                                                                                         | `array<unsigned char>[192]` (48 (π_A) + 96 (π_B) + 48 (π_C))                                                                                                                                                                                                                               |
| <span id="PHGRProof">`libzcash::PHGRProof`</span>                                                    | Compressed zkSNARK proof.[^8]                                                                                        | `CompressedG1` (g_A) + `CompressedG1` (g_A_prime) + `CompressedG2` (g_B) + `CompressedG1` (g_B_prime) + `CompressedG1` (g_C) + `CompressedG1` (g_C_prime) + `CompressedG1` (g_K) + `CompressedG1` (g_H)                                                                                    |
| <span id="SpendDescription">`SpendDescription`</span>                                                | Describes a Spend transfer.                                                                                          | `uint256` (commitment value) + `uint256` (anchor value) + `uint256` (nullifier) + `uint256` (rk) + `libzcash::GrothProof` (zkproof) + `spend_auth_sig_t` (spendAuthSig)                                                                                                                    |
| <span id="SaplingEncCiphertext">`libzcash::SaplingEncCiphertext`</span>                              | Ciphertext for the recipient to decrypt.                                                                             | `array<unsigned char>[580]`((1 + 11 + 8 + 32 + 512) + 16)                                                                                                                                                                                                                                  |
| <span id="SaplingOutCiphertext">`libzcash::SaplingOutCiphertext`</span>                              | Ciphertext for outgoing viewing key to decrypt.                                                                      | `array<unsigned char>[80]` ((32 + 32) + 16)                                                                                                                                                                                                                                                |
| <span id="OutputDescription">`OutputDescription`</span>                                              | Shielded output to a transaction. Contains data that describes an Output transfer.                                   | `uint256` (commitment value) + `uint256` (cmu) + `uint256` (ephemeralKey) + `libzcash::SaplingEncCiphertext` (encCiphertext) + `libzcash::SaplingOutCiphertext` (outCiphertext) + `libzcash::GrothProof` (zkproof)                                                                         |
| <span id="JSDescription">`JSDescription`</span>                                                      | JoinSplit description.                                                                                               | `CAmount` (vpub_old) + `CAmount` (vpub_new) + `uint256` (anchor) + `array<uint256>[2]` (nullifiers) + `array<uint256>[2]` (commitments) + `uint256` (ephemeralKey) + `uint256` (randomSeed) + `array<uint256>[2]` (message auth codes)                                                     |
| <span id="OrchardWalletTxMeta">`OrchardWalletTxMeta`</span>                                          | A container for storing information derived from a tx that is relevant to restoring Orchard wallet caches.           | `map<uint32_t, libzcash::OrchardIncomingViewingKey>` (mapOrchardActionData) + `vector<uint32_t>` (vActionsSpendingMyNotes)                                                                                                                                                                 |
| <span id="SaplingBundleTable">`SaplingBundle`</span>                                                 | The Sapling component of an authorized v5 transaction.                                                               | Check [`SaplingBundle`](#saplingbundle)                                                                                                                                                                                                                                                    |
| <span id="OrchardBundleTable">`OrchardBundle`</span>                                                 | The Orchard component of an authorized transaction.                                                                  | Check [`OrchardBundle`](#orchardbundle)                                                                                                                                                                                                                                                    |
| <span id="SaplingV4Writer">`SaplingV4Writer`</span>                                                  | Writer for the Sapling components of a v4 transaction (Sapling bundle), excluding binding signature.                 | `int64_t` (zat balance. Sapling spends - Sapling outputs) + `vector<SpendDescription>` (shielded spends) + `vector<OutputDescription>` (shielded outputs)                                                                                                                                  |
| <span id="VerificationKey">`ed25519::VerificationKey`</span>                                         | Ed25519 public key.                                                                                                  | `array<uint8_t>[32]`                                                                                                                                                                                                                                                                       |
| <span id="Signature">`ed25519::Signature`</span>                                                     | Ed25519 digital signature.                                                                                           | `array<uint8_t>[64]`                                                                                                                                                                                                                                                                       |
| <span id="CTransactionTable">`CTransaction`</span>                                                   | The basic transaction that is broadcasted on the network and contained in blocks.                                    | Check [`CTransaction`](#ctransaction)                                                                                                                                                                                                                                                      |
| <span id="CMerkleTx">`CMerkleTx`</span>                                                              | A transaction with a merkle branch linking it to the block chain.                                                    | [`CTransaction`](#CTransactionTable) + `uint256` (hashBlock) + `vector<uint256>` (vMerkleBranch) + `int` (nIndex)                                                                                                                                                                          |
| <span id="CWalletTxTable">`CWalletTx`</span>                                                         | A transaction with additional information.                                                                           | Check [`CWalletTx`](#CWalletTx)                                                                                                                                                                                                                                                            |
| <span id="OrchardIncomingViewingKey">`libzcash::OrchardIncomingViewingKey`</span>                    | Orchard incoming viewing key.                                                                                        | `array<unsigned char>[32]` (diversifier key) + `array<unsigned char>[32]` (ivk nonzero pallas scalar representation)                                                                                                                                                                       |
| <span id="SaplingFullViewingKey">`libzcash::SaplingFullViewingKey`</span>                            | Sapling full viewing key.                                                                                            | `uint256` (ak) + `uint256` (nk) + `uint256` (ovk)                                                                                                                                                                                                                                          |
| <span id="SaplingExpandedSpendingKey">`libzcash::SaplingExpandedSpendingKey`</span>                  | Sapling expanded spending key.                                                                                       | `uint256` (ask) + `uint256` (nsk) + `uint256` (ovk)                                                                                                                                                                                                                                        |
| <span id="SaplingIncomingViewingKey">`libzcash::SaplingIncomingViewingKey`</span>                    | A 32-byte value representing the incoming viewing key for a Sapling address.                                         | `uint256` (32-byte ivk in little-endian, padded with zeros in the most significant bits)                                                                                                                                                                                                   |
| <span id="SaplingExtendedFullViewingKey">`libzcash::SaplingExtendedFullViewingKey`</span>            | Sapling extended full viewing key.                                                                                   | `uint8_t` (depth) + `uint32_t` (parentFVKTag) + `uint32_t` (childIndex) + `uint256` (chaincode) + [`libzcash::SaplingFullViewingKey`](#SaplingFullViewingKey) (fvk) + `uint256` (diversifier key)                                                                                          |
| <span id="SaplingExtendedSpendingKey">`libzcash::SaplingExtendedSpendingKey`</span>                  | Sapling extended spending key.                                                                                       | `uint8_t` (depth) + `uint32_t` (parentFVKTag) + `uint32_t` (childIndex) + `uint256` (chaincode) + [`libzcash::SaplingExpandedSpendingKey`](#SaplingExpandedSpendingKey) (expsk) + `uint256` (diversifier key)                                                                              |
| <span id="SaplingPaymentAddress">`libzcash::SaplingPaymentAddress`</span>                            | Sapling payment address.                                                                                             | [`diversifier_t`](#diversifier_t) (diversifier) + `uint256` (pk_d)                                                                                                                                                                                                                         |
| <span id="ReceivingKey">`libzcash::ReceivingKey`</span>                                              | Receiving key for shielded transactions.                                                                             | `uint256` (sk_enc)                                                                                                                                                                                                                                                                         |
| <span id="SproutPaymentAddress">`libzcash::SproutPaymentAddress`</span>                              | Sprout payment address.                                                                                              | `uint256` (a_pk) + `uint256` (pk_enc)                                                                                                                                                                                                                                                      |
| <span id="OrchardRawAddress">`OrchardRawAddress`</span>                                              | Raw Orchard address. This type doesn't exist per se, but is used to avoid inline definitions.                        | [`diversifier_t`](#diversifier_t) (diversifier) + `uint256` (pk_d)                                                                                                                                                                                                                         |
| <span id="SproutViewingKey">`libzcash::SproutViewingKey`</span>                                      | Sprout viewing key.                                                                                                  | `uint256` (a_pk) + [`libzcash::ReceivingKey`](#ReceivingKey) (sk_enc)                                                                                                                                                                                                                      |
| <span id="SproutSpendingKey">`libzcash::SproutSpendingKey`</span>                                    | Sprout spending key.                                                                                                 | `uint252` (a_sk)                                                                                                                                                                                                                                                                           |
| <span id="CScriptBase">`CScriptBase`</span>                                                          | Serialized script, used inside transaction inputs and outputs.                                                       | [`prevector`](#prevector)`<28, unsigned char>` (script)                                                                                                                                                                                                                                    |
| <span id="SeedFingerprint">`libzcash::SeedFingerprint`</span>                                        | 256-bit seed fingerprint.                                                                                            | `uint256` (seed fingerprint)                                                                                                                                                                                                                                                               |
| <span id="AccountId">`libzcash::AccountId`</span>                                                    | Account identifier for HD address derivation.                                                                        | `uint32_t` (accountId)                                                                                                                                                                                                                                                                     |
| <span id="UFVKId">`libzcash::UFVKId`</span>                                                          | An internal identifier for a unified full viewing key, derived as a blake2b hash of the serialized form of the UFVK. | `uint256` (ufvkId)                                                                                                                                                                                                                                                                         |
| <span id="ReceiverType">`libzcash::ReceiverType`</span>                                              | Receiver type (P2PKH, P2SH, Sapling or Orchard).                                                                     | `uint32_t` (receiverType, 0 = P2PKH, 1 = P2SH, 2 = Sapling, 3 = Orchard)                                                                                                                                                                                                                   |
| <span id="ZcashdUnifiedAccountMetadata">`ZcashdUnifiedAccountMetadata`</span>                        | Metadata for a unified account.                                                                                      | [`libzcash::SeedFingerprint`](#SeedFingerprint) (seed fingerprint) + `uint32_t` (bip44CoinType) + [`libzcash::AccountId`](#AccountId) (accountId) + `libzcash::UFVKId` (ufvkId)                                                                                                            |
| <span id="ZcashdUnifiedAddressMetadata">`ZcashdUnifiedAddressMetadata`</span>                        | Metadata for a unified address.                                                                                      | `libzcash::UFVKId` (ufvkId) + [`libzcash::diversifier_index_t`](#diversifier_index_t) (diversifierIndex) + `vector`[`<libzcash::ReceiverType>`](#ReceiverType) (serReceiverTypes)                                                                                                          |
| <span id="Address">`Address`</span>                                                                  | Address or location of a node of the Merkle tree.                                                                    | `unsigned char`(level in merkle tree) +`uint64_t` (address index)                                                                                                                                                                                                                          |
| <span id="MerkleBridge">`MerkleBridge<H>`</span>                                                     | Information required to "update" witnesses from one state of a Merkle tree to another.                               | Check [`MerkleBridge Serialization`](#merklebridgeh-hashser--ord)                                                                                                                                                                                                                          |
| <span id="BridgeTree">`BridgeTree`</span>                                                            | Sparse representation of a Merkle tree.                                                                              | Check [`BridgeTree Serialization`](#bridgetreeh-u32-depth)                                                                                                                                                                                                                                 |
| <span id="OrchardWalletNoteCommitmentTreeWriterTable">`OrchardWalletNoteCommitmentTreeWriter`</span> | Note commitment tree for an Orchard wallet.                                                                          | Check [`OrchardWalletNoteCommitmentTreeWriter Serialization`](#orchardwalletnotecommitmenttreewriter)                                                                                                                                                                                      |
| <span id="encode">`libzcash::UnifiedFullViewingKey::Encode(string, UnifiedFullViewingKeyPtr)`</span> | Serialized Ufvk.                                                                                                     | `string` (Bech32m-encoded network HRP combined with the jumbled and Base32-encoded representation of the HRP.[^9])                                                                                                                                                                         |
| <span id="MnemonicSeed">`MnemonicSeed`</span>                                                        | Mnemonic seed.                                                                                                       | `uint32_t` (language, more information [here](#languages)) + `string` (mnemonic)                                                                                                                                                                                                           |
| <span id="ReceiverTypeSer">`ReceiverTypeSer`</span>                                                  | Serialization wrapper for reading and writing ReceiverType in CompactSize format.                                    | `CCompactSize` (size) + `uint64_t` (receiver type: 0 = P2PKH, 1 = P2SH, 2 = Sapling, 3 = Orchard)                                                                                                                                                                                          |
| <span id="CSerializeRecipientAddress">`CSerializeRecipientAddress`</span>                            | Recipient address.                                                                                                   |                                                                                                                                                                                                                                                                                            |

### More details

This section will serve as a reference for the classes whose serialization involves complex paths.
The idea is to show conditionals in a way that are easy to read.

#### SaplingBundle

> Taken from the `write_v5_bundle` function under `depends/<arch>/vendored-sources/zcash_primitives/src/transaction/components/sapling.rs`.

```cpp

// Shielded spends (without witness data)
uint256 // (commitment value)
uint256 // (nullifier)
uint256 // (rk)

// Shielded outputs (without proof)
uint256 // (commitment value)
uint256 //(cmu)
uint256 // (ephemeral key)
libzcash::SaplingEncCiphertext // (enc_ciphertext)
libzcash::SaplingOutCiphertext // (out_ciphertexts)

if (shielded_spends.length > 0 AND shielded_outputs.length > 0) {
    int64_t // (value balance)
}

if (shielded_spends.length > 0) {
    uint256 // (shielded_spends[0].anchor; the root of the Sapling commitment tree that the first spend commits to)
}

array<
    array<uint8_t>[192] // (Groth proof bytes)
> // (shielded spends zkProofs)

array<
    array<unsigned char>[64] // (redjubjub::Signature)
> // (spends auth sigs)

array<
    array<uint8_t>[192] // (Groth proof bytes)
> //  (shielded outputs zkProofs)

array<unsigned char>[64] // (binding signatures)
```

#### OrchardBundle

> Taken from the `write_v5_bundle` function under `depends/<arch>/vendored-sources/zcash_primitives/src/transaction/components/orchard.rs`.

```cpp
vector<
    uint256 // (commitment to the net value created or consumed by the action)
    uint256 // (nullifier)
    uint256 // (rk)
    uint256 // (cmx, commitment to the new note being created)

    {
        uint256 // (ephemeral key)
        array<uint8_t>[580] // (encrypted note ciphertext)
        array<uint8_t>[80] // (encrypted value that allows the holder of the outgoing cipher key for the note to recover the note plaintext)
    } // (note ciphertext)
> // (actions without auth)

byte // (flags. https://zips.z.cash/protocol/protocol.pdf#txnencoding)
int64_t // (value balance, net value moved into or out of the Orchard shielded pool)
uint256 // (anchor, the root of the Orchard commitment tree that this bundle commits to)
vector<uint8_t> // (proof components of the authorizing data)
array<
    uint8_t // (authorization for an Orchard action)
>[64] // (authorizations for each orchard action)
array<uint8_t>[64] // (binding signature)
```

#### CTransaction

> Taken from the [`SerializationOp`](https://github.com/zcash/zcash/blob/4f9fb43a3d56e2557fb2436a0689bce1ba3ae1d3/src/primitives/transaction.h#L538) function under `src/primitives/transaction.h`.

```cpp
uint32_t // (header)

if (fOverwintered) {
    uint32_t // (version group id)
}
if (isZip225V5) {
    uint32_t // (consensus branch id)
    uint32_t // (nLockTime)
    uint32_t // (nExpiryHeight)

    // Transparent Transaction Fields
    vector<CTxIn> // (vin)
    vector<CTxOut> // (vout)

    // Sapling Transaction Fields
    SaplingBundle // (saplingBundle)

    // Orchard Transaction Fields
    OrchardBundle // (orchardBundle)
} else {

    // Legacy transaction formats
    vector<CTxIn> // (vin)
    vector<CTxOut> // (vout)
    uint32_t // (nLockTime)
    if (isOverwinterV3 OR isSaplingV4 OR isFuture) {
        uint_32_t // (nExpiryHeight)
    }

    SaplingV4Writer // (saplingBundle)

    if (nVersion >= 2) {
        // These fields do not depend on fOverwintered
        vector<JSDescription>> // (vJoinSplit)
        if (vJoinSplitSize > 0) {
            ed25519::VerificationKey // (joinSplitPubKey)
            ed25519::Signature // (joinSplitSig)
        }
    }
    if ((isSaplingV4 OR isFuture) AND saplingBundle.IsPresent()) {
        array<unsigned char>[64] // (sapling bundle binding signature)
    }
}
```

#### CWalletTx

> Taken from the [`SerializationOp`](https://github.com/zcash/zcash/blob/4f9fb43a3d56e2557fb2436a0689bce1ba3ae1d3/src/wallet/wallet.h#L581) function under `src/wallet/wallet.h`.

```cpp
CMerkleTx // (transaction data with a merkle branch linking it to the block chain)
vector<CMerkleTx> // (vUnused, empty. Used to be vtxPrev)
mapValue_t // (mapValue)
mapSproutNoteData_t // (mapSproutNoteData)
vector<pair<string, string>> // (vOrderForm)
unsigned int // (fTimeReceivedIsTxTime)
unsigned int // (nTimeReceived, time received by this node)
char // (fFromMe)
char = '0' // (fSpent)
if (fOverwintered AND nVersion >= 4) {
    mapSaplingNoteData_t // (mapSaplingNoteData)
}
if (fOverwintered AND nVersion >= 5) {
    OrchardWalletTxMeta // (information relevant to restoring Orchard wallet caches)
}
```

#### MerkleBridge<H: HashSer + Ord>

> Taken from the [`write_bridge`](https://github.com/zcash/zcash/blob/4f9fb43a3d56e2557fb2436a0689bce1ba3ae1d3/src/rust/src/incremental_merkle_tree.rs#L167) function under `src/rust/src/incremental_merkle_tree.rs`.

```cpp
unsigned char = 2 // (serialization version, SER_V2)
optional<uint64_t> // (prior position)
vector<Address> // (node locations from ommers)
vector<Address + H (value)> // (ommers)
uint64_t (frontier position)

if (frontier.is_right_child()) {
    H // (hash)
    optional<H> // (most recent leaf)
    vector<H> // (the remaining leaves)
} else {
    H // (most recent leaf)
    optional<H> // (empty)
    vector<H> // (all leaves)
}
```

#### BridgeTree<H, u32, DEPTH>

> Taken from the [`write_tree`](https://github.com/zcash/zcash/blob/4f9fb43a3d56e2557fb2436a0689bce1ba3ae1d3/src/rust/src/incremental_merkle_tree.rs#L315) function under `src/rust/src/incremental_merkle_tree.rs`.

```cpp
unsigned char = '3' // (serialization version, SER_V3)
vector<MerkleBridge> // (prior bridges)
optional<MerkleBridge> // (current bridge at the tip of this tree)
vector<
    uint64_t // (position)
    uint64_t // (index in the bridges vector)
> // (map from leaf positions that have been marked to the index of the bridge whose tip is at that position in this tree's list of bridges)
vector<
    uint32_t // (checkpoint id, block height)
    uint64_t // (prior bridges length)
    vector<uint64_t> // (the set of the positions that have been marked during the period that this checkpoint is the current checkpoint)
    vector<uint64_t> // (mark positions forgotten due to notes at those positions having been spent since the position at which this checkpoint was created)
> // (checkpoints, referring to the checkpoints to which this tree may be rewound)
```

#### OrchardWalletNoteCommitmentTreeWriter

> Taken from the [`orchard_wallet_write_note_commitment_tree`](https://github.com/zcash/zcash/blob/4f9fb43a3d56e2557fb2436a0689bce1ba3ae1d3/src/rust/src/wallet.rs#L1264) function under `src/rust/src/wallet.rs`.

```cpp
unsigned char = '1' // (note state version, NOTE_STATE_V1)
optional<uint32_t> // (last checkpoint, block height)
BridgeTree<H, u32, DEPTH> // (commitment tree)

/// Note positions
vector<
    uint256 // (txid)
    uint256 // (tx height)
    // Action positions
    vector<
        uint32_t // (action index)
        uint64_t // (position)
    >
>
```

#### CSerializeRecipientAddress<libzcash::ReceiverType>

```cpp
ReceiverTypeSer // (receiver type)
if (receiverType == P2PKH) {
    uint160 // (P2PKH address)
} else if (receiverType == P2SH) {
    uint160 // (P2SH address)
} else if (receiverType == SaplingPaymentAddress) {
    libzcash::SaplingPaymentAddress // (Sapling payment address)
} else if (receiverType == OrcharRawAddress) {
    OrchardRawAddress // (Orchard raw address)
}
```

#### libzcash::UnifiedFullViewingKey::Encode(string, UnifiedFullViewingKeyPtr)

> Taken from the [`unified_full_viewing_key_serialize`](https://github.com/zcash/zcash/blob/4f9fb43a3d56e2557fb2436a0689bce1ba3ae1d3/src/rust/src/unified_keys_ffi.rs#L93) function under `src/rust/src/unified_keys_ffi.rs`.

```cpp
/*
* Bech32m encoding of (
*   HRP,
*   Jumbled padded raw encoding of the HRP, in base32
* )
*
* where HRP is the string representation of the network (main, test, regtest)
* For more information, read https://zips.z.cash/zip-0316#jumbling
*/
Bech32m(
    string, // (HRP, string representation of the network (main, test, regtest))
    f4jumble(
        {
            vector<
                uint32_t // (typecode, P2pkh, P2sh, Sapling, Orchard)
                vector<
                    /*
                    * Orchard([u8; 96]) => `(ak, nk, rivk)` each 32 bytes
                    * Sapling([u8; 128]) => `(ak, nk, ovk, dk)` each 32 bytes
                    *
                    * Pruned version of the extended public key for the BIP 44 account corresponding
                    * to the transparent address subtree from which transparent addresses are derived.
                    * This includes just the chain code (32 bytes) and the compressed public key (33 bytes).
                    * P2pkh([u8; 65]) => `(chaincode, pk)`
                    */
                    FVK
                >
            > // (raw encoding)
            array<uint8_t>[16] // (padding, HRP as bytes)
        }
    )
) // as string
```

## Encryption

WARNING: Wallet encryption is disabled. See the following for more information:

- https://zcash.github.io/zcash/user/security-warnings.html
- https://github.com/zcash/zcash/issues/1552
- https://github.com/zcash/zcash/pull/1569
- https://github.com/zcash/zcash/issues/1528

Private key encryption, along with other sensitive data, is done based on a CMasterKey, which holds a salt and random encryption key.

CMasterKeys are encrypted using AES-256-CBC[^4] using a key derived using derivation method nDerivationMethod
(0 == EVP_sha512()) and derivation iterations nDeriveIterations. vchOtherDerivationParameters is provided
for alternative algorithms which may require more parameters (such as scrypt).

Wallet Private Keys are then encrypted using AES-256-CBC with the double-sha256 of the
public key as the IV, and the master key's key as the encryption key.

The `CWallet` class holds many `CMasterKey`s, which are stored in a map keyed by an unsigned integer acting as an index.
Each `CMasterKey` is then encrypted with the user's passphrase in a function that mimics the behaviour of openssl's EVP_BytesToKey with an aes-256-cbc cipher
and sha512 message digest. Because sha512's output size (64b) is greater than the aes256 block size (16b) + aes256 key size (32b),
there's no need to process more than once (D_0). In other words, the passphrase is derived using the derivation function specified in the `CMasterKey` object,
along with the other parameters. This key is then used to encrypt the key used for encrypting private keys.

When the user changes their passphrase, they are only changing the encryption applied to the `CMasterKey`, the inner `vchCryptedKey`
(used to encrypt/decrypt private keys) is not changed. This means that we do not have to read all items in the wallet database,
decrypt them with the old key, encrypt them with the new key, and then write them back to the database again. Instead, we only
have to change the encryption applied to the `CMasterKey`, which is much less error-prone, and more secure.

## Wallet versions

The following specifies the client version numbers for particular wallet features:

```cpp
enum WalletFeature
{
    FEATURE_BASE = 10500, // the earliest version new wallets supports (only useful for getinfo's clientversion output)

    FEATURE_WALLETCRYPT = 40000, // wallet encryption
    FEATURE_COMPRPUBKEY = 60000, // compressed public keys

    FEATURE_LATEST = 60000
};
```

## Languages

```cpp
// These must match src/rust/src/zip339_ffi.rs.
// (They happen to also match the integer values correspond in the bip0039-rs crate with the
// "all-languages" feature enabled, but that's not required.)
enum Language
{
    English = 0,
    SimplifiedChinese = 1,
    TraditionalChinese = 2,
    Czech = 3,
    French = 4,
    Italian = 5,
    Japanese = 6,
    Korean = 7,
    Portuguese = 8,
    Spanish = 9,
    SIZE_HACK = 0xFFFFFFFF // needed when compiling as C
};
```

## Example wallets

The `wallet.dat` files under `dat_files/` (0 to 7) were generated while running the `qa/zcash/full_test_suite.py` tests from [Zcashd](https://github.com/zcash/zcash).

[^1]: [BerkeleyDB](https://www.oracle.com/database/technologies/related/berkeleydb.html)
[^2]: [ZIP-32: Shielded Hierarchical Deterministic Wallets](https://zips.z.cash/zip-0032)
[^3]: [Standards for Efficient Cryptography 1: Elliptic Curve Cryptography](https://www.secg.org/sec1-v2.pdf)
[^4]: [The AES-CBC Cipher Algorithm and Its Use with IPsec](https://datatracker.ietf.org/doc/html/rfc3602)
[^5]: [evp_sha512 - Linux man page](https://linux.die.net/man/3/evp_sha512)
[^6]: [The scrypt Password-Based Key Derivation Function](https://datatracker.ietf.org/doc/html/rfc7914)
[^7]: https://github.com/bitcoin/bitcoin/blob/4b5659c6b115315c9fd2902b4edd4b960a5e066e/src/wallet/scriptpubkeyman.h#L52-L100
[^8]: [Succinct Non-Interactive Zero Knowledge for a von Neumann Architecture, section 4.1: The PGHR protocol and the two elliptic curves](https://eprint.iacr.org/2013/279.pdf)
[^9]: [ZIP-316: Unified Addresses and Unified Viewing Keys](https://zips.z.cash/zip-0316)
[^10]: [ASN.1 encoding rules: Specification of Basic Encoding Rules (BER), Canonical Encoding Rules (CER) and Distinguished Encoding Rules (DER)](https://www.itu.int/ITU-T/studygroups/com17/languages/X.690-0207.pdf)
