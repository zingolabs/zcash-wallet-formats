# Zcashd's `wallet.dat`

## Important Information

[ZIP-400](https://zips.z.cash/zip-0400) documents the schema used for zcashd `v3.0.0-rc1`. Since then, the format has changed a bit.

Some work related to parsing is being done [here](https://github.com/dorianvp/zcashd-bdb-parser).

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

## Serialization framework overview

Bitcoind (and zcashd, by extension) employs a custom serialization framework to encode both `Key` and `Value` fields.
This framework handles type-specific serialization, compact sizes, optional fields, and more.
See the [serialization reference](#serialization-reference) for details on how each type is serialized.

Data is stored in a `dat` file, which are implemented as a BerkeleyDB[^1]. Each entry is serialized using the following structure:

```
<keyname_length><keyname><key>
<value(s)>
```

Where:

- `<keyname_length>` is a byte representing the length of `<keyname>`.
- `<keyname>` is an ASCII encoded string of the length `<keyname_length>` and `<key>` the binary data.
- `<key>` is the output of the serialization of each `Key`.
- `<value>` is the output of the serialization of each `Value`.

Each `value` has an associated C++ class from [zcashd](https://github.com/zcash/zcash).
Check **[this table](#serialization-reference)** to learn more about how each class is serialized.

## Serialization of Key/Value pairs by version

### v3.0.0-rc1

[Wallet source code](https://github.com/zcash/zcash/blob/v3.0.0/src/wallet/walletdb.cpp)

Taken from: https://zips.z.cash/zip-0400.
Open in fullscreen, as this table is too wide.

| Name                 | Description                                                    | Keys                                           | Value                                                                                                                  |
| -------------------- | -------------------------------------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| acc\*                | Account information.                                           | `string` (account name)                        | [`CAccount`](#CAccount)                                                                                                |
| acentry\*            | Account entry. Tracks internal transfers.                      | `string` (account name) + `uint64_t` (counter) | `CAccountingEntry`                                                                                                     |
| **bestblock**        | The current best block of the blockchain.                      | -                                              | `CBlockLocator`                                                                                                        |
| **chdseed**          | Encrypted HD seed.                                             | `uint256` (seed fingerprint)                   | `vector<unsigned char>` (WIP: how is it encrypted & stored)                                                            |
| ckey\*               | Encrypted transparent pubkey and private key.                  | [`CPubKey`](#CPubKey)                          | `vector<unsigned char>` (WIP: how is it encrypted & stored)                                                            |
| csapzkey\*           | Encrypted Sapling pubkey and private key.                      | `libzcash::SaplingIncomingViewingKey`          | `libzcash::SaplingExtendedFullViewingKey` (extended full viewing key) + `vector<unsigned char>` (vchCryptedSecret) WIP |
| **cscript**          | Serialized script, used inside transaction inputs and outputs. | `uint160`                                      | `CScript`                                                                                                              |
| czkey\*              | Encrypted Sprout pubkey and private key.                       | `libzcash::SproutPaymentAddress`               | `uint256` + `vector<unsigned char>`                                                                                    |
| **defaultkey**       | Default Transparent key.                                       | -                                              | [`CPubKey`](#CPubKey)                                                                                                  |
| destdata\*           | Adds a destination data tuple to the store.                    | `string` (WIP: address) + `string` (WIP: key)  | `string`                                                                                                               |
| **hdchain**          | Hierarchical Deterministic chain code, derived from seed.      | -                                              | `CHDChain`                                                                                                             |
| hdseed\*             | Hierarchical Deterministic seed.[^2]                           | `uint256`                                      | `RawHDSeed`                                                                                                            |
| key\*                | Transparent pubkey and privkey.                                | [`CPubKey`](#CPubKey)                          | [`CPrivKey`](#CPrivKey) + HASH256([`CPubKey`](#CPubKey) + [`CPrivKey`](#CPrivKey]))                                    |
| keymeta\*            | Transparent key metadata.                                      | [`CPubKey`](#CPubKey)                          | [`CKeyMetadata`](#CKeyMetadata)                                                                                        |
| **minversion**       | Wallet required minimal version.                               | -                                              | `int` (check [wallet versions](#wallet-versions))                                                                      |
| **mkey**             | Master key, used to encrypt public and private keys of the db. | `unsigned int`                                 | `CMasterKey`                                                                                                           |
| name\*               | Name of an address to insert in the address book.              | `string`                                       | `string`                                                                                                               |
| **orderposnext**     | Index of next tx.                                              | -                                              | `int64_t`                                                                                                              |
| pool\*               | An address look-ahead pool.[^7]                                | `int64_t`                                      | [`CKeyPool`](#CKeyPool)                                                                                                |
| purpose\*            | Short description or identifier of an address.                 | `string`                                       | `string`                                                                                                               |
| sapzaddr\*           | Sapling z-addr Incoming Viewing key and address.               | `libzcash::SaplingPaymentAddress`              | `libzcash::SaplingIncomingViewingKey`                                                                                  |
| sapextfvk\*          | Sapling Extended Full Viewing Key.                             | `libzcash::SaplingExtendedFullViewingKey`      | `char` = '1'                                                                                                           |
| sapzkey\*            | Sapling Incoming Viewing Key and Extended Spending Key         | `libzcash::SaplingIncomingViewingKey`          | `libzcash::SaplingExtendedSpendingKey`                                                                                 |
| tx\*                 | Store all transactions that are related to wallet.             | `uint256`                                      | `CWalletTx`                                                                                                            |
| **version**          | The `CLIENT_VERSION` from `clientversion.h`.                   | -                                              | `int` (check [wallet versions](#wallet-versions))                                                                      |
| vkey\*               | Sprout Viewing Keys.                                           | `libzcash::SproutViewingKey`                   | `char` = '1'                                                                                                           |
| watchs\*             | Watch-only t-addresses.                                        | `CScript`                                      | `char` = '1'                                                                                                           |
| **witnesscachesize** | Shielded Note Witness cache size.                              | -                                              | `int64_t`                                                                                                              |
| wkey\*               | Wallet key.                                                    | -                                              | -                                                                                                                      |
| zkey\*               | Sprout Payment Address and Spending Key.                       | `libzcash::SproutPaymentAddress`               | `libzcash::SproutSpendingKey`                                                                                          |
| zkeymeta\*           | Sprout Payment Address and key metadata.                       | `libzcash::SproutPaymentAddress`               | [`CKeyMetadata`](#CKeyMetadata)                                                                                        |

### v4.0.0

No changes to storage format since v3.0.0

Check out the full diff [here](./DIFF.md#v4)

### v5.0.0

#### Added and Removed Fields:

| Name                         | Description                  | Keys                           | Value                                                   |
| ---------------------------- | ---------------------------- | ------------------------------ | ------------------------------------------------------- |
| ~~acc~~                      | -                            | ~~`string`~~                   | ~~`CAccount`~~                                          |
| ~~acentry~~                  | -                            | ~~`string` + `uint64_t`~~      | ~~`CAccountingEntry`~~                                  |
| ~~hdseed~~                   | -                            | ~~`uin256`~~                   | ~~`HDSeed`~~                                            |
| ~~chdseed~~                  | -                            | ~~`uin256`~~                   | ~~`vector<unsigned char>`~~                             |
| networkinfo                  | Network identifier.          | -                              | `string`                                                |
| orchard_note_commitment_tree |                              | -                              | `OrchardWalletNoteCommitmentTreeWriter`                 |
| unifiedaccount               | Unified account information. | `ZcashdUnifiedAccountMetadata` | 0x00                                                    |
| unifiedfvk                   | Encoded unified FVK.         | `libzcash::UFVKId`             | `libzcash::UnifiedFullViewingKey::Encode(CCHainParams)` |
| unifiedaddrmeta              | Unified address metadata.    | `ZcashdUnifiedAddressMetadata` | 0x00                                                    |
| mnemonicphrase               | Mnemonic phrase.             | `uint256`                      | `MnemonicSeed`                                          |
| cmnemonicphrase              | Encrypted mnemonic phrase.   | `uint256`                      | `std::vector<unsigned char>`                            |
| mnemonichdchain              | (WIP: legacy hd data?)       | -                              | `CHDChain`                                              |

Check out the full diff [here](./DIFF.md#v5)

### v6.0.0

#### Added Fields:

| Name               | Description                                                                                                                 | Key | Value           | Serialized as             |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------- | --- | --------------- | ------------------------- |
| **bestblock**      | The current best block of the blockchain. Empty block locator so versions that require a merkle branch automatically rescan | -   | `CBlockLocator` | `vector<uint256>` (empty) |
| bestblock_nomerkle | A place in the block chain. If another node doesn't have the same branch, it can find a recent common trunk.                | -   | `CBlockLocator` | `vector<uint256>`         |

Check out the full diff [here](./DIFF.md#v6)

## Serialization reference

### Common data types

| Data Type                                       | Description                                                      | Serialized as                                                                                                                       |
| ----------------------------------------------- | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| <span id="unsigned_int">`unsigned int`</span>   | 32-bit unsigned integer.                                         | Little-endian, 4 bytes                                                                                                              |
| int32_t                                         | 32-bit signed integer.                                           | Little-endian, 4 bytes                                                                                                              |
| <span id="int64_t">`int64_t`</span>             | 64-bit signed integer.                                           | Little-endian, 8 bytes                                                                                                              |
| <span id="uint32_t">uint32_t</span>             | 32-bit unsigned integer.                                         | Little-endian, 4 bytes                                                                                                              |
| uint64_t                                        | 64-bit unsigned integer.                                         | Little-endian, 8 bytes                                                                                                              |
| <span id="uint256">uint256</span>               | An opaque blob of 256 bits without integer operations.           | Little-endian, 32 bytes                                                                                                             |
| <span id="uint252">`uint252`</span>             | Wrapper of uint256 with guarantee that first four bits are zero. | Little-endian, 32 bytes                                                                                                             |
| string                                          | UTF-8 encoded string.                                            | 1 byte (length) + bytes of the string                                                                                               |
| unsigned char                                   | Byte or octet.                                                   | 1 byte                                                                                                                              |
| bool                                            | Boolean value.                                                   | 1 byte (0x00 = false, 0x01 = true)                                                                                                  |
| <span id="pair">`pair<K, T>`</span>             | A pair of 2 elements of types `K` and `T`.                       | `T` and `K` in sequential order.                                                                                                    |
| <span id="CCompactSize">`CCompactSize`</span>   | A variable-length encoding for collection sizes.                 | 1 byte for sizes < 253, 3 bytes for sizes between 253 and 65535, 5 bytes for sizes between 65536 and 4GB, 9 bytes for larger sizes. |
| <span id="array">`array<T, N>`</span>           | An array of `N` elements of type `T`.                            | Serialized elements `T` in order. `N` is not serialized, as the array is always the same length.                                    |
| <span id="vector">`vector<T>`</span>            | Dynamic array of elements of type T.                             | [`CCompactSize`](#CCompactSize) (number of elements) + serialized elements `T` in order.                                            |
| <span id="map">`map<K, V>`</span>               | A map of key-value pairs.                                        | [`CCompactSize`](#CCompactSize) (number of key-value pairs) + serialized keys `K` and values `V` in order.                          |
| <span id="diversifier_t">`diversifier_t`</span> |                                                                  | `array<unsigned char>[11]`                                                                                                          |

### Classes

| Class                                                                                               | Description                                                                                    | Serialized as                                                                                                                                                                                                                                                                                                                   |
| --------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <span id="CAccount">`CAccount`</span>                                                               | Account information (public key).                                                              | [`CPubKey`](#CPubKey) (public key)                                                                                                                                                                                                                                                                                              |
| <span id="CPubKey">`CPubKey`</span>                                                                 | Public key.                                                                                    | [`CCompactSize`](#CCompactSize) (public key length) + [`unsigned char`](#unsigned_char)`[33 \| 65]`(public key in compressed/uncompressed format)                                                                                                                                                                               |
| <span id="CPrivKey">`CPrivKey`</span> (WIP: triple check with wallet_dumps)                         | Uncompressed private key, encoded as a DER ECPrivateKey type from section C.4 of SEC 1[^3]     | [`vector`](#vector)`<unsigned char>[214 \| 279]` (private key)                                                                                                                                                                                                                                                                  |
| <span id="CKeyMetadata">`CKeyMetadata`</span>                                                       | Key metadata.                                                                                  | [`int64_t`](#int64_t) (creation time as unix timestamp. 0 if unknown) + [`string`](#string) (optional HD/zip32 keypath[^2]) + [`uint256`](#uint256) (seed fingerprint)                                                                                                                                                          |
| <span id="CMasterKey">`CMasterKey`</span> (WIP: what is the length of vchCryptedKey)                | Master key for wallet encryption. Encrypted using AES-256-CBC.[^4]                             | `unsigned char` (vchCryptedKey) + `unsigned char[8]` (salt) + [`unsigned int`](#unsigned_int) (0 = EVP_sha512[^5] \| 1 = scrypt[^6]) + [`unsigned int`](#unsigned_int) (derivation iterations) + `vector<unsigned char> (extra parameters)`                                                                                     |
| <span id="CAccountingEntry">`CAccountingEntry`</span>                                               | Tracks an internal account transfer.                                                           | [`int64_t`](#int64_t) (credit or debit in zatoshis) + [`int64_t`](#int64_t) (unix timestamp) + `string` (other_account) + '\0' + [`map`](#map)<`string`, `string`> (metadata, includes `n` to indicate position) + [`map`](#map)<`string`, `string`> (extra information)                                                        |
| <span id="CBlockLocator">`CBlockLocator`</span>                                                     | A list of current best blocks.                                                                 | `vector<uint256>` (vector of block hashes)                                                                                                                                                                                                                                                                                      |
| <span id="CKeyPool">`CKeyPool`</span>                                                               | Pre-generated public key for receiving funds or change.                                        | [`int64_t`](#int64_t) (creation time as unix timestamp) + [`CPubKey`](#CPubKey) (public key)                                                                                                                                                                                                                                    |
| <span id="CHDChain">`CHDChain`</span> (WIP)                                                         | Crypted HDChain data.                                                                          | `int` (nVersion) + `uint256` (seed fingerprint) + `int64_t` (nTime) + `uint32_t` (accountCounter) + legacyTKeyExternalCounter + legacyTKeyInternalCounter + legacySaplingKeyCounter + `bool` (mnemonicSeedBackupConfirmed)                                                                                                      |
| <span id="RawHDSeed">`RawHDSeed`</span>                                                             | Hierarchical Deterministic seed.[^2]                                                           | `vector<unsigned char>[32]` (raw HD seed)                                                                                                                                                                                                                                                                                       |
| <span id="COutPoint">`COutPoint`</span>                                                             | A combination of a transaction hash and an index n into its vout.                              | `uint256` (hash) + `uint32_t` (index)                                                                                                                                                                                                                                                                                           |
| <span id="CTxIn">`CTxIn`</span>                                                                     | An input of a transaction.                                                                     | `COutPoint` (previous tx output) + `CScriptBase` (scriptSig) + `uint32_t` (sequence number)                                                                                                                                                                                                                                     |
| <span id="CTxOut">`CTxOut`</span>                                                                   | An output of a transaction. Contains the public key that the next input must sign to claim it. | `int64_t` (value) + `CScript` (scriptPubKey)                                                                                                                                                                                                                                                                                    |
| <span id="CTransaction">`CTransaction`</span> (WIP: header)                                         | The basic transaction that is broadcasted on the network and contained in blocks.              | `uint32_t` (header) + `uint32_t` (version group id, optional) + `vector<CTxIn>` (vin) + `vector<CTxOut>` (vout) + `uint32_t` (nLockTime) + `uint32_t` (nExpiryHeight) + `CAmount` (valueBalance) + `vector<SpendDescription>` + `OutputDescription` + `vector<JSDescription>` + `uint256` + `joinsplit_sig_t` + `binding_sig_t` |
| <span id="CMerkleTx">`CMerkleTx`</span>                                                             | A transaction with a merkle branch linking it to the block chain.                              | `CTransaction` + `uint256` (hashBlock) + `vector<uint256>` (vMerkleBranch) + `int` (nIndex)                                                                                                                                                                                                                                     |
| <span id="CWalletTx">`CWalletTx`</span>                                                             | A transaction with additional information.                                                     | `CMerkleTx` + `mapValue_t` + `mapSproutNoteData_t` + `vector<pair<string, string>>` + `unsigned int` + `unsigned int` + `char` + `char` + `mapSaplingNoteData_t`                                                                                                                                                                |
| <span id="libzcash::SaplingFullViewingKey">`libzcash::SaplingFullViewingKey`</span>                 |                                                                                                | `uint256` (ak) + `uint256` (nk) + `uint256` (ovk)                                                                                                                                                                                                                                                                               |
| <span id="libzcash::SaplingExpandedSpendingKey">`libzcash::SaplingExpandedSpendingKey`</span>       |                                                                                                | `uint256` (ask) + `uint256` (nsk) + `uint256` (ovk)                                                                                                                                                                                                                                                                             |
| <span id="libzcash::SaplingIncomingViewingKey">`libzcash::SaplingIncomingViewingKey`</span>         | A 32-byte value representing the incoming viewing key for a Sapling address.                   | `uint256` (32-byte ivk in little-endian, padded with zeros in the most significant bits)                                                                                                                                                                                                                                        |
| <span id="libzcash::SaplingExtendedFullViewingKey">`libzcash::SaplingExtendedFullViewingKey`</span> |                                                                                                | `uint8_t` (depth) + `uint32_t` (parentFVKTag) + `uint32_t` (childIndex) + `uint256` (chaincode) + `libzcash::SaplingFullViewingKey` (fvk) + `uint256` (dk)                                                                                                                                                                      |
| <span id="libzcash::SaplingExtendedSpendingKey">`libzcash::SaplingExtendedSpendingKey`</span>       |                                                                                                | `uint8_t` (depth) + `uint32_t` (parentFVKTag) + `uint32_t` (childIndex) + `uint256` (chaincode) + `libzcash::SaplingExpandedSpendingKey` (expsk) + `uint256` (dk)                                                                                                                                                               |
| <span id="libzcash::SaplingPaymentAddress">`libzcash::SaplingPaymentAddress`</span>                 |                                                                                                | `diversifier_t` (d) + `uint256` (pk_d)                                                                                                                                                                                                                                                                                          |
| <span id="libzcash::ReceivingKey">`ReceivingKey`</span>                                             |                                                                                                | `uint256` (sk_enc )                                                                                                                                                                                                                                                                                                             |
| <span id="libzcash::SproutPaymentAddress">`libzcash::SproutPaymentAddress`</span>                   |                                                                                                | `uint256` (a_pk) + `uint256` (pk_enc)                                                                                                                                                                                                                                                                                           |
| <span id="libzcash::SproutViewingKey">`libzcash::SproutViewingKey`</span>                           |                                                                                                | `uint256` (a_pk) + `libzcash::ReceivingKey` (sk_enc)                                                                                                                                                                                                                                                                            |
| <span id="libzcash::SproutSpendingKey">`libzcash::SproutSpendingKey`</span>                         |                                                                                                | `uint252` (a_sk)                                                                                                                                                                                                                                                                                                                |
| <span id="CScript">`CScript`</span>                                                                 |                                                                                                |                                                                                                                                                                                                                                                                                                                                 |
| <span id="ZcashdUnifiedAccountMetadata">`ZcashdUnifiedAccountMetadata`</span>                       |                                                                                                |                                                                                                                                                                                                                                                                                                                                 |
| <span id="libzcash::UFVKId">`libzcash::UFVKId`</span>                                               |                                                                                                |                                                                                                                                                                                                                                                                                                                                 |
| <span id="ZcashdUnifiedAddressMetadata">`ZcashdUnifiedAddressMetadata`</span>                       |                                                                                                |                                                                                                                                                                                                                                                                                                                                 |
| <span id="OrchardWalletNoteCommitmentTreeWriter">`OrchardWalletNoteCommitmentTreeWriter`</span>     |                                                                                                |                                                                                                                                                                                                                                                                                                                                 |
| <span id="boost::CChainParams">`boost::CChainParams`</span>                                         |                                                                                                |                                                                                                                                                                                                                                                                                                                                 |
| <span id="MnemonicSeed">`MnemonicSeed`</span>                                                       |                                                                                                |                                                                                                                                                                                                                                                                                                                                 |

## Encryption

Private key encryption is done based on a CMasterKey, which holds a salt and random encryption key.

CMasterKeys are encrypted using AES-256-CBC[^4] using a key derived using derivation method nDerivationMethod
(0 == EVP_sha512()) and derivation iterations nDeriveIterations. vchOtherDerivationParameters is provided
for alternative algorithms which may require more parameters (such as scrypt).

Wallet Private Keys are then encrypted using AES-256-CBC with the double-sha256 of the
public key as the IV, and the master key's key as the encryption key.

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

## Example wallets

The `wallet.dat` files under `dat_files/` (0 to 7) were generated while running the `qa/zcash/full_test_suite.py` tests from [Zcashd](https://github.com/zcash/zcash).

[^1]: https://www.oracle.com/database/technologies/related/berkeleydb.html
[^2]: https://zips.z.cash/zip-0032
[^3]: https://www.secg.org/sec1-v2.pdf
[^4]: https://datatracker.ietf.org/doc/html/rfc3602
[^5]: https://linux.die.net/man/3/evp_sha512
[^6]: https://datatracker.ietf.org/doc/html/rfc7914
[^7]: https://github.com/bitcoin/bitcoin/blob/4b5659c6b115315c9fd2902b4edd4b960a5e066e/src/wallet/scriptpubkeyman.h#L52-L100
