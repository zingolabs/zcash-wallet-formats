# Zcash Wallet Formats

This repository tracks the progress of a survey on wallet export formats, with an emphasis on zcashd and zecwallet.

Some work related to parsing is being done in the [bdb-parser (outdated)](https://github.com/dorianvp/zcashd-bdb-parser)
and in [the universal wallet parser](https://github.com/dorianvp/uzw-parser).

### Wallet Ecosystem Overview

Zcash has seen the creation of numerous wallets over time,
each catering to different user needs and offering varying levels of privacy.
Early (fullnode) wallets like Zcashd were essential for full node functionality and shielded transactions.
Over time, the ecosystem grew with mobile wallets like ZecWallet and Nighthawk,
which offered user-friendly interfaces and support for shielded transactions.

However, not all wallets have been successful. A few wallets diverged from the Zcash Improvement Proposals,
implementing features not fully aligned with the specifications,
which led to (current) compatibility issues, missing and sometimes lost funds.

This survey covers a subset of the existing wallets, some of which may appear missing, but are grouped by their
backend/library that generates their storage format. These wallets include:

- [Zcashd](./zcashd/README.md)
- [Zecwallet](./zecwallet/README.md) (Zecwallet-lite, zecwallet-light-cli, zecwallet-fullnode)
- [Zingo](./zingo/README.md) (Zingo, Zingo-pc, Zingo-cli)
- [eZcash](./ezcash/README.md)
- [Zashi](./zashi/README.md)
- [YWallet](./ywallet/README.md)
- Zenith (coming soon)
- Nighthawk (coming soon)

### Concepts

| Name                     | Defined in                              | Zecwallet | Zcashd                            | Zingo | eZcash                                  | Zashi | Ywallet |
| ------------------------ | --------------------------------------- | --------- | --------------------------------- | ----- | --------------------------------------- | ----- | ------- |
| Unified Full Viewing Key | [ZIP-316](https://zips.z.cash/zip-0316) |           | [UFVK](./zcashd/README.md#encode) |       | [UnifiedViewingKey](./ezcash/README.md) |       |         |
| Unified Address          | [ZIP-316](https://zips.z.cash/zip-0316) |           |                                   |       |                                         |       |         |
| V5 Transaction           | [ZIP-225](https://zips.z.cash/zip-0225) |           |                                   |       |                                         |       |         |
