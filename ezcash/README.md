# eZcash

eZcash stores its wallet data in a [MessagePack](https://msgpack.org/index.html) binary format.
The following schema was taken from [this JSON Schema](./wallet.schema.json).
Note that the table representation may be harder to interpret due to the nesting of fields:

```jsonc
{
  "DataRoot": {
    // Check the table below for more details
    "ZcashWallet": {...},
    "ContactManager": {...},
    "ExchangeRateRecord": {...}
  }
}
```

| Name                                                  | Type                 | Description                                                          | Properties                                                                                                                                                                     | Additional Properties                         |
| ----------------------------------------------------- | -------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------- |
| DataRoot                                              | object               | Root object that contains the wallet, contacts, and exchange rates.  | ZcashWallet, ContactManager, ExchangeRateRecord                                                                                                                                |                                               |
| ZcashWallet                                           | object OR array      |                                                                      | [!HDWallets, !Accounts, integer]                                                                                                                                               |                                               |
| Accounts                                              | array                | Array of accounts.                                                   | [Account, ... , len(Accounts)]                                                                                                                                                 |                                               |
| Account                                               | object OR array      | A Zcash account.                                                     | [!ZcashAccount, string, integer, ZcashTransactions, (integer OR null), (integer OR null), (integer OR null)]                                                                   |                                               |
| HDWallets                                             | array                |                                                                      | [HDWallet, ..., len(HDWallets)]                                                                                                                                                |                                               |
| HDWallet                                              | object OR array      |                                                                      | [!Bip39Mnemonic, !string (name), boolean]                                                                                                                                      |                                               |
| ContactManager                                        | object OR array      |                                                                      | [Contact, integer]                                                                                                                                                             |                                               |
| ExchangeRateRecord                                    | object               | The keys in this object are TradingPair values.                      | -                                                                                                                                                                              | {TradingPairValues: { DateTimeOffsetValues }} |
| Dict<K, V>                                            | object               | Dictionary from `K` to `V`.                                          | {`K`: `V`}                                                                                                                                                                     |                                               |
| Collection<T>                                         | array                | Collection of `T`.                                                   | [`T`, ..., len(Collection<T>)]                                                                                                                                                 |                                               |
| Contact                                               | object OR array      | Contact                                                              | [(integer OR null), string, !Collection<ZcashAddress>, !IntKeyedAddressMap]                                                                                                    |                                               |
| IntKeyedAddressMap                                    | object               | This object uses System.Int32 values as its keys instead of strings. | Dict<Int32, AssignedSendingAddresses>                                                                                                                                          | AssignedSendingAddresses                      |
| ZcashAddress                                          | string               | Zcash address.                                                       | string                                                                                                                                                                         |                                               |
| ZcashAccount                                          | array (1 to N items) |                                                                      | [UnifiedViewingKey, (Seed OR Mnemonic), AccountIndex, BirthdayHeight, MaxTransparentIndex]                                                                                     |                                               |
| <span id="UnifiedViewingKey">UnifiedViewingKey</span> | string               | Unified Viewing Key.                                                 | string                                                                                                                                                                         |                                               |
| Seed                                                  | array (2 to N items) | Seed (no mnemonic).                                                  | [!ZcashNetwork, string (pattern: "msgpack binary as base64")]                                                                                                                  |                                               |
| <span id="Mnemonic">Mnemonic</span>                   | array (2 to N items) |                                                                      | [string (seed phrase), string (password)]                                                                                                                                      |                                               |
| AccountIndex                                          | integer (0 to N)     | Account index.                                                       | integer                                                                                                                                                                        |                                               |
| <span id="BirthdayHeight">BirthdayHeight</span>       | integer (0 to N)     | Birthday height.                                                     | integer                                                                                                                                                                        |                                               |
| MaxTransparentIndex                                   | integer (0 to N)     | Maximum transparent address index.                                   | integer                                                                                                                                                                        |                                               |
| AssignedSendingAddresses                              | array (1 to 2 items) | Diversifier with prefix and transparent address index.               | [string (pattern: "msgpack binary as base64"), integer (transparent address index)]                                                                                            |                                               |
| ZcashTransactions                                     | array                |                                                                      | [ZcashTransaction, ..., len(ZcashTransactions)]                                                                                                                                |                                               |
| ZcashTransaction                                      | object OR array      | Zcash transaction. Check the JSON Schema file for easier reading.    | [((TxId OR null) OR null), (integer OR null), boolean, ((DateTimeOffset OR null) OR null), ((Decimal OR null) OR null), string, ZcashTransactions, ZcashTransactions, boolean] |                                               |
| TxId                                                  | string               | pattern: "msgpack binary as base64"                                  | string                                                                                                                                                                         |                                               |
| DateTimeOffset                                        | array                |                                                                      | [string (pattern: "msgpack extension -1 as base64"), integer]                                                                                                                  |                                               |
| Decimal                                               | string               | pattern: "^-?\\d\u002B(\\.\\d\u002B)?$"                              | string                                                                                                                                                                         |                                               |
| <span id="Bip39Mnemonic">Bip39Mnemonic</span>         | array (1 to N items) |                                                                      | [string (seed phrase), string (password)]                                                                                                                                      |                                               |
| ZcashNetwork                                          | integer (0 OR 1)     | 0 = MainNet, 1 = TestNet                                             | 0 OR 1                                                                                                                                                                         |                                               |

```mermaid
flowchart TB
DataRoot --> ZcashWallet
DataRoot --> ContactManager
DataRoot --> ExchangeRateRecord

ZcashWallet --> HDWallets
ZcashWallet --> Accounts

Accounts --> Account
HDWallets --> HDWallet

Account --> ZcashAccount
Account --> ZcashTransactions

ZcashAccount --> #
ZcashAccount --> BirthdayHeight
ZcashAccount --> MaxTransparentIndex
ZcashAccount --> UnifiedViewingKey
ZcashAccount --> Seed
ZcashAccount --> Mnemonic

Seed --> ZcashNetwork
Seed --> [base64]

Mnemonic --> [phrase]
Mnemonic --> [password]

HDWallet --> BIP39Mnemonic

ContactManager --> Contact

Contact --> Collection
Contact --> IntKeyedAddressMap

IntKeyedAddressMap --> AssignedSendingAddresses
```
