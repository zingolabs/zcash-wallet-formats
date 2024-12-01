# Zcashd Wallets

The `wallet.dat` files under `zcashd/` (0 to 7) were generated while running the `qa/zcash/full_test_suite.py` tests from [Zcashd](https://github.com/zcash/zcash).

## Important Information

[ZIP-400](https://zips.z.cash/zip-0400) documents the schema used for zcashd `v3.0.0-rc1`. Since then, the format has changed a bit.

Some work related to parsing is being done [here](https://github.com/dorianvp/zcashd-bdb-parser).

## Resources

- [zcash/zips #964: Update ZIP 400 for NU5/Orchard changes](https://github.com/zcash/zips/issues/964)
- https://github.com/zcash/zcash/blob/master/src/wallet/walletdb.h
- [Zcashd Wallet Guide for Exchanges](https://hackmd.io/@daira/rJVEmOCkh)
- [ZIP-400 (Wallet.dat format)](https://zips.z.cash/zip-0400)
- [ZIP-316 (Unified Addresses and Unified Viewing Keys)](https://zips.z.cash/zip-0316)
- [Bitcoin wallet.dat parser script](https://github.com/jackjack-jj/pywallet)
