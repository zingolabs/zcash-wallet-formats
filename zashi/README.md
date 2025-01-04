# Zashi

## Overview

[Zashi](https://electriccoin.co/zashi/) uses the ECC's native SDK for [Android](https://github.com/Electric-Coin-Company/zcash-android-wallet-sdk) and [iOS](https://github.com/Electric-Coin-Company/zcash-swift-wallet-sdk), which under the hood use the [zcash_client_sqlite crate](https://github.com/zcash/librustzcash/tree/main/zcash_client_sqlite) from [librustzcash](https://github.com/zcash/librustzcash).

Data is stored in an sqlite database. The following snippet is taken from the `init.rs` file in the zcash_client_sqlite crate:

```rust
let expected_tables = vec![
    db::TABLE_ACCOUNTS,
    db::TABLE_ADDRESSES,
    db::TABLE_BLOCKS,
    db::TABLE_EPHEMERAL_ADDRESSES,
    db::TABLE_NULLIFIER_MAP,
    db::TABLE_ORCHARD_RECEIVED_NOTE_SPENDS,
    db::TABLE_ORCHARD_RECEIVED_NOTES,
    db::TABLE_ORCHARD_TREE_CAP,
    db::TABLE_ORCHARD_TREE_CHECKPOINT_MARKS_REMOVED,
    db::TABLE_ORCHARD_TREE_CHECKPOINTS,
    db::TABLE_ORCHARD_TREE_SHARDS,
    db::TABLE_SAPLING_RECEIVED_NOTE_SPENDS,
    db::TABLE_SAPLING_RECEIVED_NOTES,
    db::TABLE_SAPLING_TREE_CAP,
    db::TABLE_SAPLING_TREE_CHECKPOINT_MARKS_REMOVED,
    db::TABLE_SAPLING_TREE_CHECKPOINTS,
    db::TABLE_SAPLING_TREE_SHARDS,
    db::TABLE_SCAN_QUEUE,
    db::TABLE_SCHEMERZ_MIGRATIONS,
    db::TABLE_SENT_NOTES,
    db::TABLE_SQLITE_SEQUENCE,
    db::TABLE_TRANSACTIONS,
    db::TABLE_TRANSPARENT_RECEIVED_OUTPUT_SPENDS,
    db::TABLE_TRANSPARENT_RECEIVED_OUTPUTS,
    db::TABLE_TRANSPARENT_SPEND_MAP,
    db::TABLE_TRANSPARENT_SPEND_SEARCH_QUEUE,
    db::TABLE_TX_LOCATOR_MAP,
    db::TABLE_TX_RETRIEVAL_QUEUE,
];
```

The client also generates various **indexes** and **views**.
