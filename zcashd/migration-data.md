# Wallet Migration Data

Taken from [this GitHub issue](https://github.com/zcash/zcash/issues/6873)

> Currently `zcashd` supports exporting wallet keys in a "key dump",
> but this leaves behind both a bunch of state about how those keys relate to each other,
> as well as various kinds of state that are only persisted locally and are not recoverable from the chain.
>
> We should go through the `zcashd` wallet code and `wallet.dat` file format,
> and enumerate all the kinds of data that we need to either migrate out of `zcashd`,
> or provide an alternative migration pathway for.

This document outlines the types of wallet data in `zcashd` that need to be considered for migration, categorized as follows:

1. **Recoverable Data**: Can be reconstructed from the blockchain or derived from existing properties (e.g., note commitment trees, blocks).
2. **Non-Recoverable Data**: Cannot be reconstructed from the blockchain and requires explicit migration (e.g., imported keys, address metadata).
3. **Irrelevant Data**: Not necessary for the new wallet but may be of interest for reference or the migration tool.

For (1), full node operators will need to allocate time to regenerate it.

For (2), explicit migration steps will be required to avoid loss.

For (3), it may not be migrated but could be used for reference purposes during the migration process.

## Non-recoverable data:

- Imported Keys
- Seed Phrase
- Address book information
- Network information (id)
- Unified address metadata (due to the receiver type, though this needs to be investigated further)
- HD Chain metadata

## Recoverable data (or data that can be either recovered from the blockchain or derived from other properties):

- Transaction history
- Balances
- Note commitment trees
- Block data
