# Zcash Wallet Formats

This repository tracks the progress of a survey on wallet export formats, with an emphasis on zcashd and zecwallet.

Some work related to parsing is being done in [the universal wallet parser](https://github.com/dorianvp/uzw-parser).

### Wallet Ecosystem Overview

The zcashd reference client is being deprecated, and this means that funds must be exported from the client and converted to other wallets.
The fact that there are now at least four popular major wallets and numerous lightclient wallets, each with their own formats for metadata about funds and transactions,
makes this transition challenging as does the number of Zcash address formats (transparent, sprout, sapling, and orchard)
and the proliferation of key generation formats (master keys, seeds for HD keys, and BIP-39 compatible seeds for HD keys).
A few wallets diverged from the Zcash Improvement Proposals, implementing features not fully aligned with the specifications,
which led to (current) compatibility issues, missing and sometimes lost funds.

This reflects a longer standing problem in the Zcash community: any type of migration between wallets is very difficult
(see for example forum.zcashcommunity.com/t/shifting-from-zeclite-to-zashi/47756). It's been covered by numerous GitHub Issues,
including [zcash #6873](https://github.com/zcash/zcash/issues/6873), [zips #821](https://github.com/zcash/zips/issues/821),
[zips #964](https://github.com/zcash/zips/issues/964), and [librustzcash #1552](https://github.com/zcash/librustzcash/issues/1552).

The zcashd deprecation therefore offers a major opportunity: we can create an interoperable wallet interchange format that not only serves the main purpose
of exporting data from zcashd in a standardized manner, but that also supports the interoperability of the whole Zcash wallet ecosystem going forward, ensuring
that users always have their choice of wallet and are never locked into a single provider out of fear of losing past transactions, addresses, seeds, or keys.

This helps to preserve the fairness and openness that are among Zcash's core values.

This survey covers a subset of the existing wallets, some of which may appear missing, but are grouped by their
backend/library that generates their storage format. These wallets include:

- [Zcashd](./zcashd/README.md)
- [Zecwallet](./zecwallet/README.md) (Zecwallet-lite, zecwallet-light-cli, zecwallet-fullnode)
- [Zingo](./zingo/README.md) (Zingo, Zingo-pc, Zingo-cli)
- [eZcash](./ezcash/README.md)
- [Zashi](./zashi/README.md) (zcash_client_sqlite)
- [YWallet](./ywallet/README.md)
- Zenith (coming soon)
- Nighthawk (coming soon)

### Concepts

| Name                     | Defined in                                                                                                                                                           | Zecwallet                                                     | Zcashd                                          | Zingo                                                         | eZcash                                  | Zashi | Ywallet |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------------- | --------------------------------------- | ----- | ------- |
| Unified Full Viewing Key | [ZIP-316](https://zips.z.cash/zip-0316)                                                                                                                              | `librustzcash::zcash_keys::UnifiedFullViewingKey`             | [UFVK](./zcashd/README.md#encode)               | `librustzcash::zcash_keys::UnifiedFullViewingKey`             | [UnifiedViewingKey](./ezcash/README.md) |       |         |
| Unified Address          | [ZIP-316](https://zips.z.cash/zip-0316)                                                                                                                              | `librustzcash::zcash_client_backend::address::UnifiedAddress` |                                                 | `librustzcash::zcash_client_backend::address::UnifiedAddress` |                                         |       |         |
| Unified Spending Key     |                                                                                                                                                                      |                                                               |                                                 | `librustzcash::zcash_keys::UnifiedSpendingKey`                |                                         |       |         |
| V4 Transaction           | [Zcash Protocol Specification Section 7.1 Transaction Encoding](https://zips.z.cash/protocol/protocol-dark.pdf#txnencoding)                                          | WIP: Not present in latest version.                           | [CTransaction](./zcashd/README.md#ctransaction) | `librustzcash::zcash_primitives::Transaction`                 |                                         |       |         |
| V5 Transaction           | [ZIP-225](https://zips.z.cash/zip-0225), [Zcash Protocol Specification Section 7.1 Transaction Encoding](https://zips.z.cash/protocol/protocol-dark.pdf#txnencoding) | [WalletTx](./zecwallet/README.md#wallettx)                    | [CTransaction](./zcashd/README.md#ctransaction) | `librustzcash::zcash_primitives::Transaction`                 |                                         |       |         |
