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

## Format

Each `dat` file is a BerkeleyDB store. Entries are stored as follows:

```
<keyname_length><keyname><key>
<value(s)>
```

where:

- `<keyname_length>` is a byte representing the length of `<keyname>`.
- `<keyname>` is an ASCII encoded string of the length `<keyname_length>` and `<key>` the binary data.
- `<key>` is the output of the serialization of each `Key`.
- `<value>` is the output of the serialization of each `Value`.

Each `value` has an associated C++ class from [zcashd](https://github.com/zcash/zcash). Check the **serialized as** field to learn more about each `value`.

## Source

The `wallet.dat` files under `dat_files/` (0 to 7) were generated while running the `qa/zcash/full_test_suite.py` tests from [Zcashd](https://github.com/zcash/zcash).

## v3.0.0-rc1

[Wallet source code](https://github.com/zcash/zcash/blob/v3.0.0/src/wallet/walletdb.cpp)

Taken from: https://zips.z.cash/zip-0400. Open full screen, as this table is too wide.

| Name                 | Description                                                    | Keys                                           | Value                                                               | Serialized as                                                                                          |
| -------------------- | -------------------------------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| acc\*                | Account information.                                           | `string` (account name)                        | `CAccount`                                                          | `byte` (public key length) + `unsigned char[33 \| 65]`(public key in compressed/uncompressed format)   |
| acentry\*            | Account entry. Tracks internal transfers.                      | `string` (account name) + `uint64_t` (counter) | `CAccountingEntry`                                                  | `int64_t` (credit_debit) + `int64_t` (unix timestamp) + `string` (other) (WIP: Specify LIMITED_STRING) |
| **bestblock**        | The current best block of the blockchain.                      | -                                              | `CBlockLocator`                                                     | `vector<uint256>` (list of block hashes) (WIP: how is it stored?)                                      |
| **chdseed**          | Encrypted HD seed.                                             | `uint256` (seed fingerprint)                   | `vector<unsigned char>`                                             |                                                                                                        |
| ckey\*               | Encrypted transparent pubkey and private key.                  | `vector<unsigned char>`                        | `vector<unsigned char>`                                             | `vchCryptedSecret` (WIP)                                                                               |
| csapzkey\*           | Encrypted Sapling pubkey and private key.                      | `libzcash::SaplingIncomingViewingKey`          | `libzcash::SaplingExtendedFullViewingKey` + `vector<unsigned char>` |                                                                                                        |
| **cscript**          | Serialized script, used inside transaction inputs and outputs. | `uint160`                                      | `CScript`                                                           |                                                                                                        |
| czkey\*              | Encrypted Sprout pubkey and private key.                       | `libzcash::SproutPaymentAddress`               | `uint256` + `vector<unsigned char>`                                 |                                                                                                        |
| **defaultkey**       | Default Transparent key.                                       | -                                              | `CPubKey`                                                           |                                                                                                        |
| destdata\*           | Adds a destination data tuple to the store.                    | `string` + `string`                            | `string`                                                            |                                                                                                        |
| **hdchain**          | Hierarchical Deterministic chain code, derived from seed.      | -                                              | `CHDChain`                                                          |                                                                                                        |
| hdseed\*             | Hierarchical Deterministic seed.                               | `uint256`                                      | `RawHDSeed`                                                         |                                                                                                        |
| key\*                | Transparent pubkey and privkey.                                | `CPubKey`                                      | `CPrivKey`                                                          | `private_key` + SHA256(`public_key`+`private_key`)                                                     |
| keymeta\*            | Transparent key metadata.                                      | `CPubKey`                                      | `CKeyMetadata`                                                      |                                                                                                        |
| **minversion**       | Wallet required minimal version.                               | -                                              | `int` (check [wallet versions](#wallet-versions))                   |                                                                                                        |
| **mkey**             | Master key, used to encrypt public and private keys of the db. | `unsigned int`                                 | `CMasterKey`                                                        |                                                                                                        |
| name\*               | Name of an address to insert in the address book.              | `string`                                       | `string`                                                            | `string`                                                                                               |
| **orderposnext**     | Index of next tx.                                              | -                                              | `int64_t`                                                           |                                                                                                        |
| pool\*               | Key pool.                                                      | `int64_t`                                      | `CKeyPool`                                                          | `CKeyPool`                                                                                             |
| purpose\*            | Short description or identifier of an address.                 | `string`                                       | `string`                                                            |                                                                                                        |
| sapzaddr\*           | Sapling z-addr Incoming Viewing key and address.               | `libzcash::SaplingPaymentAddress`              | `libzcash::SaplingIncomingViewingKey`                               |                                                                                                        |
| sapextfvk\*          | Sapling Extended Full Viewing Key.                             | -                                              | -                                                                   |                                                                                                        |
| sapzkey\*            | Sapling Incoming Viewing Key and Extended Spending Key         | `libzcash::SaplingIncomingViewingKey`          | `libzcash::SaplingExtendedSpendingKey`                              |                                                                                                        |
| tx\*                 | Store all transactions that are related to wallet.             | `uint256`                                      | `CWalletTx`                                                         |                                                                                                        |
| **version**          | The `CLIENT_VERSION` from `clientversion.h`.                   | -                                              | `int`                                                               |                                                                                                        |
| vkey\*               | Sprout Viewing Keys.                                           | `libzcash::SproutViewingKey`                   | `char`                                                              |                                                                                                        |
| watchs\*             | Watch-only t-addresses.                                        | `CScript`                                      | `char`                                                              |                                                                                                        |
| **witnesscachesize** | Shielded Note Witness cache size.                              | -                                              | `int64_t`                                                           |                                                                                                        |
| wkey\*               | Wallet key.                                                    | -                                              | -                                                                   |                                                                                                        |
| zkey\*               | Sprout Payment Address and Spending Key.                       | `libzcash::SproutPaymentAddress`               | `libzcash::SproutSpendingKey`                                       |                                                                                                        |
| zkeymeta\*           | Sprout Payment Address and key metadata.                       | `libzcash::SproutPaymentAddress`               | `CKeyMetadata`                                                      |                                                                                                        |

## v4.0.0

No changes to storage format since v3.0.0

Check out the full diff [here](#v4)

## v5.0.0

### Added and Removed Fields:

| Name                         | Description | Keys                           | Value                                   | Serialized as |
| ---------------------------- | ----------- | ------------------------------ | --------------------------------------- | ------------- |
| ~~acc~~                      |             | ~~`string`~~                   | ~~`CAccount`~~                          |               |
| ~~acentry~~                  |             | ~~`string` + `uint64_t`~~      | ~~`CAccountingEntry`~~                  |               |
| ~~hdseed~~                   |             | ~~`uin256`~~                   | ~~`HDSeed`~~                            |               |
| ~~chdseed~~                  |             | ~~`uin256`~~                   | ~~`vector<unsigned char>`~~             |               |
| networkinfo                  |             | -                              | `string`                                |               |
| orchard_note_commitment_tree |             | -                              | `OrchardWalletNoteCommitmentTreeWriter` |               |
| unifiedaccount               |             | `ZcashdUnifiedAccountMetadata` | 0x00                                    |               |
| unifiedfvk                   |             | `libzcash::UFVKId`             | `boost::CChainParams`                   |               |
| unifiedaddrmeta              |             | `ZcashdUnifiedAddressMetadata` | 0x00                                    |               |
| mnemonicphrase               |             | `uint256`                      | `MnemonicSeed`                          |               |
| cmnemonicphrase              |             | `uint256`                      | `std::vector<unsigned char>`            |               |
| mnemonichdchain              |             | -                              | `CHDChain`                              |               |

Check out the full diff [here](#v5)

## v6.0.0

### Added Fields:

| Name               | Description                                                                                                                 | Key | Value           | Serialized as             |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------- | --- | --------------- | ------------------------- |
| **bestblock**      | The current best block of the blockchain. Empty block locator so versions that require a merkle branch automatically rescan | -   | `CBlockLocator` | `vector<uint256>` (empty) |
| bestblock_nomerkle | A place in the block chain. If another node doesn't have the same branch, it can find a recent common trunk.                | -   | `CBlockLocator` | `vector<uint256>`         |

Check out the full diff [here](#v6)

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

## Full Diffs

<a id="v4"></a>

## v3.0.0 <> v4.0.0

```diff
diff --git a/src/wallet/walletdb.cpp b/src/wallet/walletdb.cpp
index af35606ee..52222ea6d 100644
--- a/src/wallet/walletdb.cpp
+++ b/src/wallet/walletdb.cpp
@@ -8,6 +8,7 @@
 #include "consensus/validation.h"
 #include "key_io.h"
 #include "main.h"
+#include "proof_verifier.h"
 #include "protocol.h"
 #include "serialize.h"
 #include "sync.h"
@@ -458,6 +459,8 @@ ReadKeyValue(CWallet* pwallet, CDataStream& ssKey, CDataStream& ssValue,
              CWalletScanState &wss, string& strType, string& strErr)
 {
     try {
+        KeyIO keyIO(Params());
+
         // Unserialize
         // Taking advantage of the fact that pair serialization
         // is just the two items serialized one after the other
@@ -466,13 +469,13 @@ ReadKeyValue(CWallet* pwallet, CDataStream& ssKey, CDataStream& ssValue,
         {
             string strAddress;
             ssKey >> strAddress;
-            ssValue >> pwallet->mapAddressBook[DecodeDestination(strAddress)].name;
+            ssValue >> pwallet->mapAddressBook[keyIO.DecodeDestination(strAddress)].name;
         }
         else if (strType == "purpose")
         {
             string strAddress;
             ssKey >> strAddress;
-            ssValue >> pwallet->mapAddressBook[DecodeDestination(strAddress)].purpose;
+            ssValue >> pwallet->mapAddressBook[keyIO.DecodeDestination(strAddress)].purpose;
         }
         else if (strType == "tx")
         {
@@ -481,7 +484,7 @@ ReadKeyValue(CWallet* pwallet, CDataStream& ssKey, CDataStream& ssValue,
             CWalletTx wtx;
             ssValue >> wtx;
             CValidationState state;
-            auto verifier = libzcash::ProofVerifier::Strict();
+            auto verifier = ProofVerifier::Strict();
             if (!(CheckTransaction(wtx, state, verifier) && (wtx.GetHash() == hash) && state.IsValid()))
                 return false;

@@ -829,7 +832,7 @@ ReadKeyValue(CWallet* pwallet, CDataStream& ssKey, CDataStream& ssValue,
             ssKey >> strAddress;
             ssKey >> strKey;
             ssValue >> strValue;
-            if (!pwallet->LoadDestData(DecodeDestination(strAddress), strKey, strValue))
+            if (!pwallet->LoadDestData(keyIO.DecodeDestination(strAddress), strKey, strValue))
             {
                 strErr = "Error reading wallet database: LoadDestData failed";
                 return false;
@@ -1144,7 +1147,7 @@ void ThreadFlushWalletDB(const string& strFile)
                         bitdb.CloseDb(strFile);
                         bitdb.CheckpointLSN(strFile);

-                        bitdb.mapFileUseCount.erase(mi++);
+                        bitdb.mapFileUseCount.erase(mi);
                         LogPrint("db", "Flushed %s %dms\n", strFile, GetTimeMillis() - nStart);
                     }
                 }
```

<a id="v5"></a>

## v4.0.0 <> v5.0.0

```diff
diff --git a/src/wallet/walletdb.cpp b/src/wallet/walletdb.cpp
index 52222ea6d..2055b3f57 100644
--- a/src/wallet/walletdb.cpp
+++ b/src/wallet/walletdb.cpp
@@ -6,33 +6,37 @@
 #include "wallet/walletdb.h"

 #include "consensus/validation.h"
+#include "fs.h"
 #include "key_io.h"
 #include "main.h"
 #include "proof_verifier.h"
 #include "protocol.h"
 #include "serialize.h"
+#include "script/standard.h"
 #include "sync.h"
 #include "util.h"
 #include "utiltime.h"
 #include "wallet/wallet.h"
 #include "zcash/Proof.hpp"

-#include <boost/filesystem.hpp>
-#include <boost/foreach.hpp>
 #include <boost/scoped_ptr.hpp>
 #include <boost/thread.hpp>
+#include <atomic>
+#include <string>

 using namespace std;

 static uint64_t nAccountingEntryNumber = 0;

+static std::atomic<unsigned int> nWalletDBUpdateCounter;
+
 //
 // CWalletDB
 //

 bool CWalletDB::WriteName(const string& strAddress, const string& strName)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(make_pair(string("name"), strAddress), strName);
 }

@@ -40,37 +44,37 @@ bool CWalletDB::EraseName(const string& strAddress)
 {
     // This should only be used for sending addresses, never for receiving addresses,
     // receiving addresses must always have an address book entry if they're not change return.
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Erase(make_pair(string("name"), strAddress));
 }

 bool CWalletDB::WritePurpose(const string& strAddress, const string& strPurpose)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(make_pair(string("purpose"), strAddress), strPurpose);
 }

 bool CWalletDB::ErasePurpose(const string& strPurpose)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Erase(make_pair(string("purpose"), strPurpose));
 }

-bool CWalletDB::WriteTx(uint256 hash, const CWalletTx& wtx)
+bool CWalletDB::WriteTx(const CWalletTx& wtx)
 {
-    nWalletDBUpdated++;
-    return Write(std::make_pair(std::string("tx"), hash), wtx);
+    nWalletDBUpdateCounter++;
+    return Write(std::make_pair(std::string("tx"), wtx.GetHash()), wtx);
 }

 bool CWalletDB::EraseTx(uint256 hash)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Erase(std::make_pair(std::string("tx"), hash));
 }

 bool CWalletDB::WriteKey(const CPubKey& vchPubKey, const CPrivKey& vchPrivKey, const CKeyMetadata& keyMeta)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;

     if (!Write(std::make_pair(std::string("keymeta"), vchPubKey),
                keyMeta, false))
@@ -90,7 +94,7 @@ bool CWalletDB::WriteCryptedKey(const CPubKey& vchPubKey,
                                 const CKeyMetadata &keyMeta)
 {
     const bool fEraseUnencryptedKey = true;
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;

     if (!Write(std::make_pair(std::string("keymeta"), vchPubKey),
             keyMeta))
@@ -112,7 +116,7 @@ bool CWalletDB::WriteCryptedZKey(const libzcash::SproutPaymentAddress & addr,
                                  const CKeyMetadata &keyMeta)
 {
     const bool fEraseUnencryptedKey = true;
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;

     if (!Write(std::make_pair(std::string("zkeymeta"), addr), keyMeta))
         return false;
@@ -132,8 +136,8 @@ bool CWalletDB::WriteCryptedSaplingZKey(
     const CKeyMetadata &keyMeta)
 {
     const bool fEraseUnencryptedKey = true;
-    nWalletDBUpdated++;
-    auto ivk = extfvk.fvk.in_viewing_key();
+    nWalletDBUpdateCounter++;
+    auto ivk = extfvk.ToIncomingViewingKey();

     if (!Write(std::make_pair(std::string("sapzkeymeta"), ivk), keyMeta))
         return false;
@@ -150,13 +154,13 @@ bool CWalletDB::WriteCryptedSaplingZKey(

 bool CWalletDB::WriteMasterKey(unsigned int nID, const CMasterKey& kMasterKey)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(std::make_pair(std::string("mkey"), nID), kMasterKey, true);
 }

 bool CWalletDB::WriteZKey(const libzcash::SproutPaymentAddress& addr, const libzcash::SproutSpendingKey& key, const CKeyMetadata &keyMeta)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;

     if (!Write(std::make_pair(std::string("zkeymeta"), addr), keyMeta))
         return false;
@@ -164,11 +168,12 @@ bool CWalletDB::WriteZKey(const libzcash::SproutPaymentAddress& addr, const libz
     // pair is: tuple_key("zkey", paymentaddress) --> secretkey
     return Write(std::make_pair(std::string("zkey"), addr), key, false);
 }
+
 bool CWalletDB::WriteSaplingZKey(const libzcash::SaplingIncomingViewingKey &ivk,
                 const libzcash::SaplingExtendedSpendingKey &key,
                 const CKeyMetadata &keyMeta)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;

     if (!Write(std::make_pair(std::string("sapzkeymeta"), ivk), keyMeta))
         return false;
@@ -180,58 +185,96 @@ bool CWalletDB::WriteSaplingPaymentAddress(
     const libzcash::SaplingPaymentAddress &addr,
     const libzcash::SaplingIncomingViewingKey &ivk)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;

     return Write(std::make_pair(std::string("sapzaddr"), addr), ivk, false);
 }

 bool CWalletDB::WriteSproutViewingKey(const libzcash::SproutViewingKey &vk)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(std::make_pair(std::string("vkey"), vk), '1');
 }

 bool CWalletDB::EraseSproutViewingKey(const libzcash::SproutViewingKey &vk)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Erase(std::make_pair(std::string("vkey"), vk));
 }

 bool CWalletDB::WriteSaplingExtendedFullViewingKey(
     const libzcash::SaplingExtendedFullViewingKey &extfvk)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(std::make_pair(std::string("sapextfvk"), extfvk), '1');
 }

 bool CWalletDB::EraseSaplingExtendedFullViewingKey(
     const libzcash::SaplingExtendedFullViewingKey &extfvk)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Erase(std::make_pair(std::string("sapextfvk"), extfvk));
 }

+//
+// Orchard wallet persistence
+//
+
+bool CWalletDB::WriteOrchardWitnesses(const OrchardWallet& wallet) {
+    nWalletDBUpdateCounter++;
+    return Write(
+            std::string("orchard_note_commitment_tree"),
+            OrchardWalletNoteCommitmentTreeWriter(wallet));
+}
+
+//
+// Unified address & key storage
+//
+
+bool CWalletDB::WriteUnifiedAccountMetadata(const ZcashdUnifiedAccountMetadata& keymeta)
+{
+    nWalletDBUpdateCounter++;
+    return Write(std::make_pair(std::string("unifiedaccount"), keymeta), 0x00);
+}
+
+bool CWalletDB::WriteUnifiedFullViewingKey(const libzcash::UnifiedFullViewingKey& ufvk)
+{
+    nWalletDBUpdateCounter++;
+    auto ufvkId = ufvk.GetKeyID(Params());
+    return Write(std::make_pair(std::string("unifiedfvk"), ufvkId), ufvk.Encode(Params()));
+}
+
+bool CWalletDB::WriteUnifiedAddressMetadata(const ZcashdUnifiedAddressMetadata& addrmeta)
+{
+    nWalletDBUpdateCounter++;
+    return Write(std::make_pair(std::string("unifiedaddrmeta"), addrmeta), 0x00);
+}
+
+//
+//
+//
+
 bool CWalletDB::WriteCScript(const uint160& hash, const CScript& redeemScript)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(std::make_pair(std::string("cscript"), hash), *(const CScriptBase*)(&redeemScript), false);
 }

 bool CWalletDB::WriteWatchOnly(const CScript &dest)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(std::make_pair(std::string("watchs"), *(const CScriptBase*)(&dest)), '1');
 }

 bool CWalletDB::EraseWatchOnly(const CScript &dest)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Erase(std::make_pair(std::string("watchs"), *(const CScriptBase*)(&dest)));
 }

 bool CWalletDB::WriteBestBlock(const CBlockLocator& locator)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(std::string("bestblock"), locator);
 }

@@ -242,19 +285,19 @@ bool CWalletDB::ReadBestBlock(CBlockLocator& locator)

 bool CWalletDB::WriteOrderPosNext(int64_t nOrderPosNext)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(std::string("orderposnext"), nOrderPosNext);
 }

 bool CWalletDB::WriteDefaultKey(const CPubKey& vchPubKey)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(std::string("defaultkey"), vchPubKey);
 }

 bool CWalletDB::WriteWitnessCacheSize(int64_t nWitnessCacheSize)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(std::string("witnesscachesize"), nWitnessCacheSize);
 }

@@ -265,13 +308,13 @@ bool CWalletDB::ReadPool(int64_t nPool, CKeyPool& keypool)

 bool CWalletDB::WritePool(int64_t nPool, const CKeyPool& keypool)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(std::make_pair(std::string("pool"), nPool), keypool);
 }

 bool CWalletDB::ErasePool(int64_t nPool)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Erase(std::make_pair(std::string("pool"), nPool));
 }

@@ -280,156 +323,17 @@ bool CWalletDB::WriteMinVersion(int nVersion)
     return Write(std::string("minversion"), nVersion);
 }

-bool CWalletDB::ReadAccount(const string& strAccount, CAccount& account)
-{
-    account.SetNull();
-    return Read(make_pair(string("acc"), strAccount), account);
-}
-
-bool CWalletDB::WriteAccount(const string& strAccount, const CAccount& account)
-{
-    return Write(make_pair(string("acc"), strAccount), account);
-}
-
-bool CWalletDB::WriteAccountingEntry(const uint64_t nAccEntryNum, const CAccountingEntry& acentry)
-{
-    return Write(std::make_pair(std::string("acentry"), std::make_pair(acentry.strAccount, nAccEntryNum)), acentry);
-}
-
-bool CWalletDB::WriteAccountingEntry(const CAccountingEntry& acentry)
-{
-    return WriteAccountingEntry(++nAccountingEntryNumber, acentry);
-}
-
-CAmount CWalletDB::GetAccountCreditDebit(const string& strAccount)
-{
-    list<CAccountingEntry> entries;
-    ListAccountCreditDebit(strAccount, entries);
-
-    CAmount nCreditDebit = 0;
-    BOOST_FOREACH (const CAccountingEntry& entry, entries)
-        nCreditDebit += entry.nCreditDebit;
-
-    return nCreditDebit;
-}
-
-void CWalletDB::ListAccountCreditDebit(const string& strAccount, list<CAccountingEntry>& entries)
-{
-    bool fAllAccounts = (strAccount == "*");
-
-    Dbc* pcursor = GetCursor();
-    if (!pcursor)
-        throw runtime_error("CWalletDB::ListAccountCreditDebit(): cannot create DB cursor");
-    unsigned int fFlags = DB_SET_RANGE;
-    while (true)
-    {
-        // Read next record
-        CDataStream ssKey(SER_DISK, CLIENT_VERSION);
-        if (fFlags == DB_SET_RANGE)
-            ssKey << std::make_pair(std::string("acentry"), std::make_pair((fAllAccounts ? string("") : strAccount), uint64_t(0)));
-        CDataStream ssValue(SER_DISK, CLIENT_VERSION);
-        int ret = ReadAtCursor(pcursor, ssKey, ssValue, fFlags);
-        fFlags = DB_NEXT;
-        if (ret == DB_NOTFOUND)
-            break;
-        else if (ret != 0)
-        {
-            pcursor->close();
-            throw runtime_error("CWalletDB::ListAccountCreditDebit(): error scanning DB");
-        }
-
-        // Unserialize
-        string strType;
-        ssKey >> strType;
-        if (strType != "acentry")
-            break;
-        CAccountingEntry acentry;
-        ssKey >> acentry.strAccount;
-        if (!fAllAccounts && acentry.strAccount != strAccount)
-            break;
-
-        ssValue >> acentry;
-        ssKey >> acentry.nEntryNo;
-        entries.push_back(acentry);
-    }
-
-    pcursor->close();
-}
-
-DBErrors CWalletDB::ReorderTransactions(CWallet* pwallet)
+bool CWalletDB::WriteRecipientMapping(const uint256& txid, const libzcash::RecipientAddress& address, const libzcash::UnifiedAddress& ua)
 {
-    LOCK(pwallet->cs_wallet);
-    // Old wallets didn't have any defined order for transactions
-    // Probably a bad idea to change the output of this
-
-    // First: get all CWalletTx and CAccountingEntry into a sorted-by-time multimap.
-    typedef pair<CWalletTx*, CAccountingEntry*> TxPair;
-    typedef multimap<int64_t, TxPair > TxItems;
-    TxItems txByTime;
-
-    for (map<uint256, CWalletTx>::iterator it = pwallet->mapWallet.begin(); it != pwallet->mapWallet.end(); ++it)
-    {
-        CWalletTx* wtx = &((*it).second);
-        txByTime.insert(make_pair(wtx->nTimeReceived, TxPair(wtx, (CAccountingEntry*)0)));
-    }
-    list<CAccountingEntry> acentries;
-    ListAccountCreditDebit("", acentries);
-    BOOST_FOREACH(CAccountingEntry& entry, acentries)
-    {
-        txByTime.insert(make_pair(entry.nTime, TxPair((CWalletTx*)0, &entry)));
-    }
-
-    int64_t& nOrderPosNext = pwallet->nOrderPosNext;
-    nOrderPosNext = 0;
-    std::vector<int64_t> nOrderPosOffsets;
-    for (TxItems::iterator it = txByTime.begin(); it != txByTime.end(); ++it)
-    {
-        CWalletTx *const pwtx = (*it).second.first;
-        CAccountingEntry *const pacentry = (*it).second.second;
-        int64_t& nOrderPos = (pwtx != 0) ? pwtx->nOrderPos : pacentry->nOrderPos;
-
-        if (nOrderPos == -1)
-        {
-            nOrderPos = nOrderPosNext++;
-            nOrderPosOffsets.push_back(nOrderPos);
-
-            if (pwtx)
-            {
-                if (!WriteTx(pwtx->GetHash(), *pwtx))
-                    return DB_LOAD_FAIL;
-            }
-            else
-                if (!WriteAccountingEntry(pacentry->nEntryNo, *pacentry))
-                    return DB_LOAD_FAIL;
-        }
-        else
-        {
-            int64_t nOrderPosOff = 0;
-            BOOST_FOREACH(const int64_t& nOffsetStart, nOrderPosOffsets)
-            {
-                if (nOrderPos >= nOffsetStart)
-                    ++nOrderPosOff;
-            }
-            nOrderPos += nOrderPosOff;
-            nOrderPosNext = std::max(nOrderPosNext, nOrderPos + 1);
-
-            if (!nOrderPosOff)
-                continue;
-
-            // Since we're changing the order, write it back
-            if (pwtx)
-            {
-                if (!WriteTx(pwtx->GetHash(), *pwtx))
-                    return DB_LOAD_FAIL;
-            }
-            else
-                if (!WriteAccountingEntry(pacentry->nEntryNo, *pacentry))
-                    return DB_LOAD_FAIL;
-        }
+    auto recipientReceiver = libzcash::RecipientAddressToReceiver(address);
+    // Check that recipient address exists in given UA.
+    if (!ua.ContainsReceiver(recipientReceiver)) {
+        return false;
     }
-    WriteOrderPosNext(nOrderPosNext);

-    return DB_LOAD_OK;
+    std::pair<uint256, CSerializeRecipientAddress> key = std::make_pair(txid, CSerializeRecipientAddress(address));
+    std::string uaString = KeyIO(Params()).EncodePaymentAddress(ua);
+    return Write(std::make_pair(std::string("recipientmapping"), key), uaString);
 }

 class CWalletScanState {
@@ -485,8 +389,13 @@ ReadKeyValue(CWallet* pwallet, CDataStream& ssKey, CDataStream& ssValue,
             ssValue >> wtx;
             CValidationState state;
             auto verifier = ProofVerifier::Strict();
-            if (!(CheckTransaction(wtx, state, verifier) && (wtx.GetHash() == hash) && state.IsValid()))
+            if (!(
+                CheckTransaction(wtx, state, verifier) &&
+                (wtx.GetHash() == hash) &&
+                state.IsValid())
+            ) {
                 return false;
+            }

             // Undo serialize changes in 31600
             if (31404 <= wtx.fTimeReceivedIsTxTime && wtx.fTimeReceivedIsTxTime <= 31703)
@@ -495,9 +404,10 @@ ReadKeyValue(CWallet* pwallet, CDataStream& ssKey, CDataStream& ssValue,
                 {
                     char fTmp;
                     char fUnused;
-                    ssValue >> fTmp >> fUnused >> wtx.strFromAccount;
-                    strErr = strprintf("LoadWallet() upgrading tx ver=%d %d '%s' %s",
-                                       wtx.fTimeReceivedIsTxTime, fTmp, wtx.strFromAccount, hash.ToString());
+                    std::string unused_string;
+                    ssValue >> fTmp >> fUnused >> unused_string;
+                    strErr = strprintf("LoadWallet() upgrading tx ver=%d %d %s",
+                                       wtx.fTimeReceivedIsTxTime, fTmp, hash.ToString());
                     wtx.fTimeReceivedIsTxTime = fTmp;
                 }
                 else
@@ -511,24 +421,7 @@ ReadKeyValue(CWallet* pwallet, CDataStream& ssKey, CDataStream& ssValue,
             if (wtx.nOrderPos == -1)
                 wss.fAnyUnordered = true;

-            pwallet->AddToWallet(wtx, true, NULL);
-        }
-        else if (strType == "acentry")
-        {
-            string strAccount;
-            ssKey >> strAccount;
-            uint64_t nNumber;
-            ssKey >> nNumber;
-            if (nNumber > nAccountingEntryNumber)
-                nAccountingEntryNumber = nNumber;
-
-            if (!wss.fAnyUnordered)
-            {
-                CAccountingEntry acentry;
-                ssValue >> acentry;
-                if (acentry.nOrderPos == -1)
-                    wss.fAnyUnordered = true;
-            }
+            pwallet->LoadWalletTx(wtx);
         }
         else if (strType == "watchs")
         {
@@ -789,6 +682,62 @@ ReadKeyValue(CWallet* pwallet, CDataStream& ssKey, CDataStream& ssValue,
         {
             ssValue >> pwallet->vchDefaultKey;
         }
+        else if (strType == "unifiedfvk")
+        {
+            libzcash::UFVKId fp;
+            ssKey >> fp;
+
+            std::string ufvkenc;
+            ssValue >> ufvkenc;
+
+            auto ufvkopt = libzcash::UnifiedFullViewingKey::Decode(ufvkenc, Params());
+            if (ufvkopt.has_value()) {
+                auto ufvk = ufvkopt.value();
+                if (fp != ufvk.GetKeyID(Params())) {
+                    strErr = "Error reading wallet database: key fingerprint did not match decoded key";
+                    return false;
+                }
+                if (!pwallet->LoadUnifiedFullViewingKey(ufvk)) {
+                    strErr = "Error reading wallet database: LoadUnifiedFullViewingKey failed.";
+                    return false;
+                }
+            } else {
+                strErr = "Error reading wallet database: failed to decode unified full viewing key.";
+                return false;
+            }
+        }
+        else if (strType == "unifiedaccount")
+        {
+            auto acct = ZcashdUnifiedAccountMetadata::Read(ssKey);
+
+            uint8_t value;
+            ssValue >> value;
+            if (value != 0x00) {
+                strErr = "Error reading wallet database: invalid unified account metadata.";
+                return false;
+            }
+
+            if (!pwallet->LoadUnifiedAccountMetadata(acct)) {
+                strErr = "Error reading wallet database: account ID mismatch for unified spending key.";
+                return false;
+            };
+        }
+        else if (strType == "unifiedaddrmeta")
+        {
+            auto keymeta = ZcashdUnifiedAddressMetadata::Read(ssKey);
+
+            uint8_t value;
+            ssValue >> value;
+            if (value != 0x00) {
+                strErr = "Error reading wallet database: invalid unified address metadata.";
+                return false;
+            }
+
+            if (!pwallet->LoadUnifiedAddressMetadata(keymeta)) {
+                strErr = "Error reading wallet database: cannot reproduce previously generated unified address.";
+                return false;
+            }
+        }
         else if (strType == "pool")
         {
             int64_t nIndex;
@@ -842,6 +791,37 @@ ReadKeyValue(CWallet* pwallet, CDataStream& ssKey, CDataStream& ssValue,
         {
             ssValue >> pwallet->nWitnessCacheSize;
         }
+        else if (strType == "mnemonicphrase")
+        {
+            uint256 seedFp;
+            ssKey >> seedFp;
+            auto seed = MnemonicSeed::Read(ssValue);
+
+            if (seed.Fingerprint() != seedFp)
+            {
+                strErr = "Error reading wallet database: mnemonic phrase corrupt";
+                return false;
+            }
+
+            if (!pwallet->LoadMnemonicSeed(seed))
+            {
+                strErr = "Error reading wallet database: LoadMnemonicSeed failed";
+                return false;
+            }
+        }
+        else if (strType == "cmnemonicphrase")
+        {
+            uint256 seedFp;
+            vector<unsigned char> vchCryptedSecret;
+            ssKey >> seedFp;
+            ssValue >> vchCryptedSecret;
+            if (!pwallet->LoadCryptedMnemonicSeed(seedFp, vchCryptedSecret))
+            {
+                strErr = "Error reading wallet database: LoadCryptedMnemonicSeed failed";
+                return false;
+            }
+            wss.fIsEncrypted = true;
+        }
         else if (strType == "hdseed")
         {
             uint256 seedFp;
@@ -856,7 +836,7 @@ ReadKeyValue(CWallet* pwallet, CDataStream& ssKey, CDataStream& ssValue,
                 return false;
             }

-            if (!pwallet->LoadHDSeed(seed))
+            if (!pwallet->LoadLegacyHDSeed(seed))
             {
                 strErr = "Error reading wallet database: LoadHDSeed failed";
                 return false;
@@ -868,18 +848,54 @@ ReadKeyValue(CWallet* pwallet, CDataStream& ssKey, CDataStream& ssValue,
             vector<unsigned char> vchCryptedSecret;
             ssKey >> seedFp;
             ssValue >> vchCryptedSecret;
-            if (!pwallet->LoadCryptedHDSeed(seedFp, vchCryptedSecret))
+            if (!pwallet->LoadCryptedLegacyHDSeed(seedFp, vchCryptedSecret))
             {
                 strErr = "Error reading wallet database: LoadCryptedHDSeed failed";
                 return false;
             }
             wss.fIsEncrypted = true;
         }
-        else if (strType == "hdchain")
+        else if (strType == "mnemonichdchain")
+        {
+            auto chain = CHDChain::Read(ssValue);
+            pwallet->SetMnemonicHDChain(chain, true);
+        }
+        else if (strType == "networkinfo")
+        {
+            std::pair<std::string, std::string> networkInfo;
+            ssValue >> networkInfo;
+            if (!pwallet->CheckNetworkInfo(networkInfo)) {
+                strErr = "Error in wallet database: unexpected network";
+                return false;
+            }
+        }
+        else if (strType == "recipientmapping")
+        {
+            uint256 txid;
+            std::string rawUa;
+            ssKey >> txid;
+            auto recipient = CSerializeRecipientAddress::Read(ssKey);
+            ssValue >> rawUa;
+
+            auto ua = libzcash::UnifiedAddress::Parse(Params(), rawUa);
+            if (!ua.has_value()) {
+                strErr = "Error in wallet database: non-UnifiedAddress in recipientmapping";
+                return false;
+            }
+
+            auto recipientReceiver = libzcash::RecipientAddressToReceiver(recipient);
+
+            if (!ua.value().ContainsReceiver(recipientReceiver)) {
+                strErr = "Error in wallet database: recipientmapping UA does not contain recipient";
+                return false;
+            }
+
+            pwallet->LoadRecipientMapping(txid, RecipientMapping(ua.value(), recipient));
+        }
+        else if (strType == "orchard_note_commitment_tree")
         {
-            CHDChain chain;
-            ssValue >> chain;
-            pwallet->SetHDChain(chain, true);
+            auto loader = pwallet->GetOrchardNoteCommitmentTreeLoader();
+            ssValue >> loader;
         }
     } catch (...)
     {
@@ -892,6 +908,8 @@ static bool IsKeyType(string strType)
 {
     return (strType== "key" || strType == "wkey" ||
             strType == "hdseed" || strType == "chdseed" ||
+            strType == "mnemonicphrase" || strType == "cmnemonicphrase" ||
+            strType == "mnemonichdchain" ||
             strType == "zkey" || strType == "czkey" ||
             strType == "sapzkey" || strType == "csapzkey" ||
             strType == "vkey" || strType == "sapextfvk" ||
@@ -905,8 +923,8 @@ DBErrors CWalletDB::LoadWallet(CWallet* pwallet)
     bool fNoncriticalErrors = false;
     DBErrors result = DB_LOAD_OK;

+    LOCK(pwallet->cs_wallet);
     try {
-        LOCK(pwallet->cs_wallet);
         int nMinVersion = 0;
         if (Read((string)"minversion", nMinVersion))
         {
@@ -919,7 +937,7 @@ DBErrors CWalletDB::LoadWallet(CWallet* pwallet)
         Dbc* pcursor = GetCursor();
         if (!pcursor)
         {
-            LogPrintf("Error getting wallet database cursor\n");
+            LogPrintf("LoadWallet: Error getting wallet database cursor.");
             return DB_CORRUPT;
         }

@@ -933,7 +951,7 @@ DBErrors CWalletDB::LoadWallet(CWallet* pwallet)
                 break;
             else if (ret != 0)
             {
-                LogPrintf("Error reading next record from wallet database\n");
+                LogPrintf("LoadWallet: Error reading next record from wallet database.");
                 return DB_CORRUPT;
             }

@@ -941,31 +959,49 @@ DBErrors CWalletDB::LoadWallet(CWallet* pwallet)
             string strType, strErr;
             if (!ReadKeyValue(pwallet, ssKey, ssValue, wss, strType, strErr))
             {
-                // losing keys is considered a catastrophic error, anything else
-                // we assume the user can live with:
-                if (IsKeyType(strType))
+                if (strType == "networkinfo") {
+                    // example: running mainnet, but this wallet.dat is from testnet
+                    result = DB_WRONG_NETWORK;
+                } else if (result != DB_WRONG_NETWORK && IsKeyType(strType)) {
+                    // losing keys is considered a catastrophic error
+                    LogPrintf("LoadWallet: Unable to read key/value for key type %s (%d)", strType, result);
                     result = DB_CORRUPT;
-                else
-                {
+                } else {
                     // Leave other errors alone, if we try to fix them we might make things worse.
                     fNoncriticalErrors = true; // ... but do warn the user there is something wrong.
-                    if (strType == "tx")
+                    if (strType == "tx") {
                         // Rescan if there is a bad transaction record:
                         SoftSetBoolArg("-rescan", true);
+                    }
                 }
             }
             if (!strErr.empty())
-                LogPrintf("%s\n", strErr);
+                LogPrintf("LoadWallet: %s", strErr);
         }
         pcursor->close();
+
+        // Load unified address/account/key caches based on what was loaded
+        if (!pwallet->LoadCaches()) {
+            // We can be more permissive of certain kinds of failures during
+            // loading; for now we'll interpret failure to reconstruct the
+            // caches to be "as bad" as losing keys.
+            LogPrintf("LoadWallet: Failed to restore cached wallet data from chain state.");
+            result = DB_CORRUPT;
+        }
     }
     catch (const boost::thread_interrupted&) {
         throw;
     }
+    catch (const std::exception& e) {
+        LogPrintf("LoadWallet: Caught exception: %s", e.what());
+        result = DB_CORRUPT;
+    }
     catch (...) {
+        LogPrintf("LoadWallet: Caught something that wasn't a std::exception.");
         result = DB_CORRUPT;
     }

+
     if (fNoncriticalErrors && result == DB_LOAD_OK)
         result = DB_NONCRITICAL_ERROR;

@@ -986,8 +1022,8 @@ DBErrors CWalletDB::LoadWallet(CWallet* pwallet)
     if ((wss.nKeys + wss.nCKeys) != wss.nKeyMeta)
         pwallet->nTimeFirstKey = 1; // 0 would be considered 'no value'

-    BOOST_FOREACH(uint256 hash, wss.vWalletUpgrade)
-        WriteTx(hash, pwallet->mapWallet[hash]);
+    for (uint256 hash : wss.vWalletUpgrade)
+        WriteTx(pwallet->mapWallet[hash]);

     // Rewrite encrypted wallets of versions 0.4.0 and 0.5.0rc:
     if (wss.fIsEncrypted && (wss.nFileVersion == 40000 || wss.nFileVersion == 50000))
@@ -997,7 +1033,7 @@ DBErrors CWalletDB::LoadWallet(CWallet* pwallet)
         WriteVersion(CLIENT_VERSION);

     if (wss.fAnyUnordered)
-        result = ReorderTransactions(pwallet);
+        result = pwallet->ReorderTransactions();

     return result;
 }
@@ -1086,7 +1122,7 @@ DBErrors CWalletDB::ZapWalletTx(CWallet* pwallet, vector<CWalletTx>& vWtx)
         return err;

     // erase each wallet TX
-    BOOST_FOREACH (uint256& hash, vTxHash) {
+    for (uint256& hash : vTxHash) {
         if (!EraseTx(hash))
             return DB_CORRUPT;
     }
@@ -1106,20 +1142,20 @@ void ThreadFlushWalletDB(const string& strFile)
     if (!GetBoolArg("-flushwallet", DEFAULT_FLUSHWALLET))
         return;

-    unsigned int nLastSeen = nWalletDBUpdated;
-    unsigned int nLastFlushed = nWalletDBUpdated;
+    unsigned int nLastSeen = CWalletDB::GetUpdateCounter();
+    unsigned int nLastFlushed = CWalletDB::GetUpdateCounter();
     int64_t nLastWalletUpdate = GetTime();
     while (true)
     {
         MilliSleep(500);

-        if (nLastSeen != nWalletDBUpdated)
+        if (nLastSeen != CWalletDB::GetUpdateCounter())
         {
-            nLastSeen = nWalletDBUpdated;
+            nLastSeen = CWalletDB::GetUpdateCounter();
             nLastWalletUpdate = GetTime();
         }

-        if (nLastFlushed != nWalletDBUpdated && GetTime() - nLastWalletUpdate >= 2)
+        if (nLastFlushed != CWalletDB::GetUpdateCounter() && GetTime() - nLastWalletUpdate >= 2)
         {
             TRY_LOCK(bitdb.cs_db,lockDb);
             if (lockDb)
@@ -1140,7 +1176,7 @@ void ThreadFlushWalletDB(const string& strFile)
                     if (mi != bitdb.mapFileUseCount.end())
                     {
                         LogPrint("db", "Flushing %s\n", strFile);
-                        nLastFlushed = nWalletDBUpdated;
+                        nLastFlushed = CWalletDB::GetUpdateCounter();
                         int64_t nStart = GetTimeMillis();

                         // Flush wallet file so it's self contained
@@ -1172,16 +1208,16 @@ bool BackupWallet(const CWallet& wallet, const string& strDest)
                 bitdb.mapFileUseCount.erase(wallet.strWalletFile);

                 // Copy wallet file
-                boost::filesystem::path pathSrc = GetDataDir() / wallet.strWalletFile;
-                boost::filesystem::path pathDest(strDest);
-                if (boost::filesystem::is_directory(pathDest))
+                fs::path pathSrc = GetDataDir() / wallet.strWalletFile;
+                fs::path pathDest(strDest);
+                if (fs::is_directory(pathDest))
                     pathDest /= wallet.strWalletFile;

                 try {
-                    boost::filesystem::copy_file(pathSrc, pathDest, boost::filesystem::copy_option::overwrite_if_exists);
+                    fs::copy_file(pathSrc, pathDest, fs::copy_option::overwrite_if_exists);
                     LogPrintf("copied %s to %s\n", wallet.strWalletFile, pathDest.string());
                     return true;
-                } catch (const boost::filesystem::filesystem_error& e) {
+                } catch (const fs::filesystem_error& e) {
                     LogPrintf("error copying %s to %s - %s\n", wallet.strWalletFile, pathDest.string(), e.what());
                     return false;
                 }
@@ -1238,19 +1274,24 @@ bool CWalletDB::Recover(CDBEnv& dbenv, const std::string& filename, bool fOnlyKe
         LogPrintf("Cannot create database file %s\n", filename);
         return false;
     }
-    CWallet dummyWallet;
+    CWallet dummyWallet(Params());
     CWalletScanState wss;

     DbTxn* ptxn = dbenv.TxnBegin();
-    BOOST_FOREACH(CDBEnv::KeyValPair& row, salvagedData)
+    for (CDBEnv::KeyValPair& row : salvagedData)
     {
         if (fOnlyKeys)
         {
             CDataStream ssKey(row.first, SER_DISK, CLIENT_VERSION);
             CDataStream ssValue(row.second, SER_DISK, CLIENT_VERSION);
             string strType, strErr;
-            bool fReadOK = ReadKeyValue(&dummyWallet, ssKey, ssValue,
+            bool fReadOK;
+            {
+                // Required in LoadKeyMetadata():
+                LOCK(dummyWallet.cs_wallet);
+                fReadOK = ReadKeyValue(&dummyWallet, ssKey, ssValue,
                                         wss, strType, strErr);
+            }
             if (!IsKeyType(strType))
                 continue;
             if (!fReadOK)
@@ -1268,6 +1309,13 @@ bool CWalletDB::Recover(CDBEnv& dbenv, const std::string& filename, bool fOnlyKe
     ptxn->commit(0);
     pdbCopy->close(0);

+    // Try to load the wallet's caches, uncovering inconsistencies in wallet
+    // records like missing viewing key records despite existing account
+    // records.
+    if (!dummyWallet.LoadCaches()) {
+        LogPrintf("WARNING: wallet caches could not be reconstructed; salvaged wallet file may have omissions");
+    }
+
     return fSuccess;
 }

@@ -1278,31 +1326,47 @@ bool CWalletDB::Recover(CDBEnv& dbenv, const std::string& filename)

 bool CWalletDB::WriteDestData(const std::string &address, const std::string &key, const std::string &value)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Write(std::make_pair(std::string("destdata"), std::make_pair(address, key)), value);
 }

 bool CWalletDB::EraseDestData(const std::string &address, const std::string &key)
 {
-    nWalletDBUpdated++;
+    nWalletDBUpdateCounter++;
     return Erase(std::make_pair(std::string("destdata"), std::make_pair(address, key)));
 }

+bool CWalletDB::WriteNetworkInfo(const std::string& networkId)
+{
+    nWalletDBUpdateCounter++;
+    std::pair<std::string, std::string> networkInfo(PACKAGE_NAME, networkId);
+    return Write(std::string("networkinfo"), networkInfo);
+}
+
+bool CWalletDB::WriteMnemonicSeed(const MnemonicSeed& seed)
+{
+    nWalletDBUpdateCounter++;
+    return Write(std::make_pair(std::string("mnemonicphrase"), seed.Fingerprint()), seed);
+}
+
+bool CWalletDB::WriteCryptedMnemonicSeed(const uint256& seedFp, const std::vector<unsigned char>& vchCryptedSecret)
+{
+    nWalletDBUpdateCounter++;
+    return Write(std::make_pair(std::string("cmnemonicphrase"), seedFp), vchCryptedSecret);
+}

-bool CWalletDB::WriteHDSeed(const HDSeed& seed)
+bool CWalletDB::WriteMnemonicHDChain(const CHDChain& chain)
 {
-    nWalletDBUpdated++;
-    return Write(std::make_pair(std::string("hdseed"), seed.Fingerprint()), seed.RawSeed());
+    nWalletDBUpdateCounter++;
+    return Write(std::string("mnemonichdchain"), chain);
 }

-bool CWalletDB::WriteCryptedHDSeed(const uint256& seedFp, const std::vector<unsigned char>& vchCryptedSecret)
+void CWalletDB::IncrementUpdateCounter()
 {
-    nWalletDBUpdated++;
-    return Write(std::make_pair(std::string("chdseed"), seedFp), vchCryptedSecret);
+    nWalletDBUpdateCounter++;
 }

-bool CWalletDB::WriteHDChain(const CHDChain& chain)
+unsigned int CWalletDB::GetUpdateCounter()
 {
-    nWalletDBUpdated++;
-    return Write(std::string("hdchain"), chain);
+    return nWalletDBUpdateCounter;
 }
```

<a id="v6"></a>

## v5.0.0 <> v6.0.0

```diff
diff --git a/src/wallet/walletdb.cpp b/src/wallet/walletdb.cpp
index 2055b3f57..96d82cfe6 100644
--- a/src/wallet/walletdb.cpp
+++ b/src/wallet/walletdb.cpp
@@ -1,5 +1,6 @@
 // Copyright (c) 2009-2010 Satoshi Nakamoto
 // Copyright (c) 2009-2014 The Bitcoin Core developers
+// Copyright (c) 2016-2023 The Zcash developers
 // Distributed under the MIT software license, see the accompanying
 // file COPYING or https://www.opensource.org/licenses/mit-license.php .

@@ -14,8 +15,8 @@
 #include "serialize.h"
 #include "script/standard.h"
 #include "sync.h"
-#include "util.h"
-#include "utiltime.h"
+#include "util/system.h"
+#include "util/time.h"
 #include "wallet/wallet.h"
 #include "zcash/Proof.hpp"

@@ -275,12 +276,14 @@ bool CWalletDB::EraseWatchOnly(const CScript &dest)
 bool CWalletDB::WriteBestBlock(const CBlockLocator& locator)
 {
     nWalletDBUpdateCounter++;
-    return Write(std::string("bestblock"), locator);
+    Write(std::string("bestblock"), CBlockLocator()); // Write empty block locator so versions that require a merkle branch automatically rescan
+    return Write(std::string("bestblock_nomerkle"), locator);
 }

 bool CWalletDB::ReadBestBlock(CBlockLocator& locator)
 {
-    return Read(std::string("bestblock"), locator);
+    if (Read(std::string("bestblock"), locator) && !locator.vHave.empty()) return true;
+    return Read(std::string("bestblock_nomerkle"), locator);
 }

 bool CWalletDB::WriteOrderPosNext(int64_t nOrderPosNext)
@@ -971,6 +974,7 @@ DBErrors CWalletDB::LoadWallet(CWallet* pwallet)
                     fNoncriticalErrors = true; // ... but do warn the user there is something wrong.
                     if (strType == "tx") {
                         // Rescan if there is a bad transaction record:
+                        LogPrintf("LoadWallet: Malformed transaction data encountered; starting with -rescan.");
                         SoftSetBoolArg("-rescan", true);
                     }
                 }
@@ -1133,7 +1137,7 @@ DBErrors CWalletDB::ZapWalletTx(CWallet* pwallet, vector<CWalletTx>& vWtx)
 void ThreadFlushWalletDB(const string& strFile)
 {
     // Make this thread recognisable as the wallet flushing thread
-    RenameThread("zcash-wallet");
+    RenameThread("zc-wallet-flush");

     static bool fOneThread;
     if (fOneThread)
@@ -1214,7 +1218,7 @@ bool BackupWallet(const CWallet& wallet, const string& strDest)
                     pathDest /= wallet.strWalletFile;

                 try {
-                    fs::copy_file(pathSrc, pathDest, fs::copy_option::overwrite_if_exists);
+                    fs::copy_file(pathSrc, pathDest, fs::copy_options::overwrite_existing);
                     LogPrintf("copied %s to %s\n", wallet.strWalletFile, pathDest.string());
                     return true;
                 } catch (const fs::filesystem_error& e) {
```
