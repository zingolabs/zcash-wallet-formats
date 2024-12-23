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

## Constants

The following constants are used throughout this document:

- PRIVATE_KEY_SIZE: 279
- COMPRESSED_PRIVATE_KEY_SIZE: 214

## Format

Each `dat` file is a BerkeleyDB [^1] store. Entries are stored as follows:

```
<keyname_length><keyname><key>
<value(s)>
```

where:

- `<keyname_length>` is a byte representing the length of `<keyname>`.
- `<keyname>` is an ASCII encoded string of the length `<keyname_length>` and `<key>` the binary data.
- `<key>` is the output of the serialization of each `Key`.
- `<value>` is the output of the serialization of each `Value`.

Each `value` has an associated C++ class from [zcashd](https://github.com/zcash/zcash).
Check **[this table](#class-serialization-reference)** to learn more about how each class is serialized.

## Source

The `wallet.dat` files under `dat_files/` (0 to 7) were generated while running the `qa/zcash/full_test_suite.py` tests from [Zcashd](https://github.com/zcash/zcash).

## v3.0.0-rc1

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
| hdseed\*             | Hierarchical Deterministic seed. [^2]                          | `uint256`                                      | `RawHDSeed`                                                                                                            |
| key\*                | Transparent pubkey and privkey.                                | [`CPubKey`](#CPubKey)                          | [`CPrivKey`](#CPrivKey) + HASH256([`CPubKey`](#CPubKey) + [`CPrivKey`](#CPrivKey]))                                    |
| keymeta\*            | Transparent key metadata.                                      | [`CPubKey`](#CPubKey)                          | `CKeyMetadata`                                                                                                         |
| **minversion**       | Wallet required minimal version.                               | -                                              | `int` (check [wallet versions](#wallet-versions))                                                                      |
| **mkey**             | Master key, used to encrypt public and private keys of the db. | `unsigned int`                                 | `CMasterKey`                                                                                                           |
| name\*               | Name of an address to insert in the address book.              | `string`                                       | `string`                                                                                                               |
| **orderposnext**     | Index of next tx.                                              | -                                              | `int64_t`                                                                                                              |
| pool\*               | Key pool.                                                      | `int64_t`                                      | `CKeyPool`                                                                                                             |
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
| zkeymeta\*           | Sprout Payment Address and key metadata.                       | `libzcash::SproutPaymentAddress`               | `CKeyMetadata`                                                                                                         |

## v4.0.0

No changes to storage format since v3.0.0

Check out the full diff [here](./DIFF.md#v4)

## v5.0.0

### Added and Removed Fields:

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

## v6.0.0

### Added Fields:

| Name               | Description                                                                                                                 | Key | Value           | Serialized as             |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------- | --- | --------------- | ------------------------- |
| **bestblock**      | The current best block of the blockchain. Empty block locator so versions that require a merkle branch automatically rescan | -   | `CBlockLocator` | `vector<uint256>` (empty) |
| bestblock_nomerkle | A place in the block chain. If another node doesn't have the same branch, it can find a recent common trunk.                | -   | `CBlockLocator` | `vector<uint256>`         |

Check out the full diff [here](./DIFF.md#v6)

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

## Class serialization reference

| Class                                                                                               | Description                                                         | Serialized as                                                                                                                                                                                                                   |
| --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <span id="CAccount">`CAccount`</span>                                                               | Account information (punlic key).                                   | [`CPubKey`](#CPubKey) (public key)                                                                                                                                                                                              |
| <span id="CPubKey">`CPubKey`</span>                                                                 | Public key.                                                         | `byte` (public key length) + `unsigned char[33 \| 65]`(public key in compressed/uncompressed format)                                                                                                                            |
| <span id="CPrivKey">`CPrivKey` (WIP)</span>                                                         | Serialized private key, with all parameters included.               | `private_key`                                                                                                                                                                                                                   |
| <span id="CKeyMetadata">`CKeyMetadata`</span> (WIP)                                                 |                                                                     | `string` (hdKeypath, optional HD/zip32 keypath) + `uint256` (seed fingerprint)                                                                                                                                                  |
| <span id="CMasterKey">`CMasterKey`</span> (WIP)                                                     | Master key for wallet encryption. Encrypted using AES-256-CBC. [^3] | `vector<unsigned char>` (vchCryptedKey) + `vector<unsigned char>` (vchSalt) + `unsigned int` (0 = EVP_sha512 [^4] \| 1 = scrypt [^5]) + `unsigned int nDeriveIterations` + `vector<unsigned char> vchOtherDerivationParameters` |
| <span id="CAccountingEntry">`CAccountingEntry`</span> (WIP: LIMITED_STRING)                         |                                                                     | `int64_t` (credit_debit) + `int64_t` (unix timestamp) + `string` (other_account)                                                                                                                                                |
| <span id="CBlockLocator">`CBlockLocator` (WIP: how are they stored?)                                |                                                                     | `vector<uint256>` (vector of block hashes)                                                                                                                                                                                      |
| <span id="CKeyPool">`CKeyPool`</span> (WIP)                                                         |                                                                     | `int64_t` (blockheight) + `CPubKey` (public key)                                                                                                                                                                                |
| <span id="CHDChain">`CHDChain`</span> (WIP)                                                         | Crypted HDChain data.                                               | `int` (nVersion) + `uint256` (seed fingerprint) + `int64_t` (nTime) + `uint32_t` (accountCounter) + legacyTKeyExternalCounter + legacyTKeyInternalCounter + legacySaplingKeyCounter + `bool` (mnemonicSeedBackupConfirmed)      |
| <span id="RawHDSeed">`RawHDSeed`</span>                                                             |                                                                     |                                                                                                                                                                                                                                 |
| <span id="CWallet">`CWallet`</span>                                                                 |                                                                     |                                                                                                                                                                                                                                 |
| <span id="CWalletTx">`CWalletTx`</span>                                                             |                                                                     |                                                                                                                                                                                                                                 |
| <span id="libzcash::SaplingIncomingViewingKey">`libzcash::SaplingIncomingViewingKey`</span>         |                                                                     | 32-byte ivk in little-endian, padded with zeros in the most significant bits                                                                                                                                                    |
| <span id="libzcash::SaplingExtendedFullViewingKey">`libzcash::SaplingExtendedFullViewingKey`</span> |                                                                     |                                                                                                                                                                                                                                 |
| <span id="libzcash::SaplingExtendedSpendingKey">`libzcash::SaplingExtendedSpendingKey`</span>       |                                                                     |                                                                                                                                                                                                                                 |
| <span id="libzcash::SaplingPaymentAddress">`libzcash::SaplingPaymentAddress`</span>                 |                                                                     |                                                                                                                                                                                                                                 |
| <span id="libzcash::SproutPaymentAddress">`libzcash::SproutPaymentAddress`</span>                   |                                                                     | `uint256` (spending key) + `uint256` (public key)                                                                                                                                                                               |
| <span id="libzcash::SproutViewingKey">`libzcash::SproutViewingKey`</span>                           |                                                                     |                                                                                                                                                                                                                                 |
| <span id="libzcash::SproutSpendingKey">`libzcash::SproutSpendingKey`</span>                         |                                                                     |                                                                                                                                                                                                                                 |
| <span id="CScript">`CScript`</span>                                                                 |                                                                     |                                                                                                                                                                                                                                 |
| <span id="ZcashdUnifiedAccountMetadata">`ZcashdUnifiedAccountMetadata`</span>                       |                                                                     |                                                                                                                                                                                                                                 |
| <span id="libzcash::UFVKId">`libzcash::UFVKId`</span>                                               |                                                                     |                                                                                                                                                                                                                                 |
| <span id="ZcashdUnifiedAddressMetadata">`ZcashdUnifiedAddressMetadata`</span>                       |                                                                     |                                                                                                                                                                                                                                 |
| <span id="OrchardWalletNoteCommitmentTreeWriter">`OrchardWalletNoteCommitmentTreeWriter`</span>     |                                                                     |                                                                                                                                                                                                                                 |
| <span id="boost::CChainParams">`boost::CChainParams`</span>                                         |                                                                     |                                                                                                                                                                                                                                 |
| <span id="MnemonicSeed">`MnemonicSeed`</span>                                                       |                                                                     |                                                                                                                                                                                                                                 |

## References

[^1]: https://www.oracle.com/database/technologies/related/berkeleydb.html
[^2]: https://zips.z.cash/zip-0032
[^3]: https://datatracker.ietf.org/doc/html/rfc3602
[^4]: https://linux.die.net/man/3/evp_sha512
[^5]: https://datatracker.ietf.org/doc/html/rfc7914
