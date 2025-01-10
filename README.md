# Zcash Wallet Formats

This repository tracks the progress of a survey on wallet export formats, with an emphasis on zcashd and zecwallet.

Some work related to parsing is being done in the [bdb-parser (outdated)](https://github.com/dorianvp/zcashd-bdb-parser)
and in [the universal wallet parser](https://github.com/dorianvp/uzw-parser).

### Wallets

Check out the following surveys:

- [Zcashd](./zcashd/README.md)
- [Zecwallet](./zecwallet/README.md)
- [Zashi](./zashi/README.md)
- [Zingo](./zingo/README.md)
- Ywallet (coming soon)

### Wallet Ecosystem Overview (WIP)

### Concepts

| Name                     | Defined in                               | Zecwallet | Zcashd                            | Zingo | eZcash                                  | Zashi | Ywallet |
| ------------------------ | ---------------------------------------- | --------- | --------------------------------- | ----- | --------------------------------------- | ----- | ------- |
| Unified Full Viewing Key | [ZIP-0316](https://zips.z.cash/zip-0316) |           | [UFVK](./zcashd/README.md#encode) |       | [UnifiedViewingKey](./ezcash/README.md) |       |         |
| Unified Address          | [ZIP-0316](https://zips.z.cash/zip-0316) |           |                                   |       |                                         |       |         |
