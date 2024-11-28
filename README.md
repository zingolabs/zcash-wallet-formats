# Zcashd Wallets

The `wallet.dat` files under `zcashd/` (0 to 7) were generated while running the `qa/zcash/full_test_suite.py` tests from [Zcashd](https://github.com/zcash/zcash).

## Important Information

[ZIP-400](https://zips.z.cash/zip-0400) documents the schema used for zcashd `v3.0.0-rc1`. However, zcashd version `4.7.0` [introduced **Unified Addresses**](https://hackmd.io/@daira/rJVEmOCkh#Changes-to-the-zcashd-wallet).

## Resources

- https://github.com/zcash/zcash/blob/master/src/wallet/walletdb.h
- [Zcashd Wallet Guide for Exchanges](https://hackmd.io/@daira/rJVEmOCkh)
- [ZIP-400 (Wallet.dat format)](https://zips.z.cash/zip-0400)
- [ZIP-316 (Unified Addresses and Unified Viewing Keys)](https://zips.z.cash/zip-0316)
- [Bitcoin wallet.dat parser script](https://github.com/jackjack-jj/pywallet)
