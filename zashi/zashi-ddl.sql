-- Accounts
CREATE TABLE "accounts" (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    uuid BLOB NOT NULL,
    account_kind INTEGER NOT NULL DEFAULT 0,
    key_source TEXT,
    hd_seed_fingerprint BLOB,
    hd_account_index INTEGER,
    ufvk TEXT,
    uivk TEXT NOT NULL,
    orchard_fvk_item_cache BLOB,
    sapling_fvk_item_cache BLOB,
    p2pkh_fvk_item_cache BLOB,
    birthday_height INTEGER NOT NULL,
    birthday_sapling_tree_size INTEGER,
    birthday_orchard_tree_size INTEGER,
    recover_until_height INTEGER,
    has_spend_key INTEGER NOT NULL DEFAULT 1,
    CHECK (
      (
        account_kind = 0
        AND hd_seed_fingerprint IS NOT NULL
        AND hd_account_index IS NOT NULL
        AND ufvk IS NOT NULL
      )
      OR
      (
        account_kind = 1
        AND (hd_seed_fingerprint IS NULL) = (hd_account_index IS NULL)
      )
    )
);

CREATE UNIQUE INDEX accounts_uuid ON accounts (uuid);
CREATE UNIQUE INDEX accounts_ufvk ON accounts (ufvk);
CREATE UNIQUE INDEX accounts_uivk ON accounts (uivk);
CREATE UNIQUE INDEX hd_account ON accounts (hd_seed_fingerprint, hd_account_index);

-- Addresses
CREATE TABLE "addresses" (
    account_id INTEGER NOT NULL,
    diversifier_index_be BLOB NOT NULL,
    address TEXT NOT NULL,
    cached_transparent_receiver_address TEXT,
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    CONSTRAINT diversification UNIQUE (account_id, diversifier_index_be)
);

CREATE INDEX "addresses_accounts" ON "addresses" (
    "account_id" ASC
);

-- Ephemeral Addresses
CREATE TABLE ephemeral_addresses (
    account_id INTEGER NOT NULL,
    address_index INTEGER NOT NULL,
    -- nullability of this column is controlled by the index_range_and_address_nullity check
    address TEXT,
    used_in_tx INTEGER,
    seen_in_tx INTEGER,
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (used_in_tx) REFERENCES transactions(id_tx),
    FOREIGN KEY (seen_in_tx) REFERENCES transactions(id_tx),
    PRIMARY KEY (account_id, address_index),
    CONSTRAINT ephemeral_addr_uniq UNIQUE (address),
    CONSTRAINT used_implies_seen CHECK (
        used_in_tx IS NULL OR seen_in_tx IS NOT NULL
    ),
    CONSTRAINT index_range_and_address_nullity CHECK (
        (address_index BETWEEN 0 AND 0x7FFFFFFF AND address IS NOT NULL) OR
        (address_index BETWEEN 0x80000000 AND 0x7FFFFFFF + 20 AND address IS NULL AND used_in_tx IS NULL AND seen_in_tx IS NULL)
    )
) WITHOUT ROWID;

-- Blocks
CREATE TABLE blocks (
    height INTEGER PRIMARY KEY,
    hash BLOB NOT NULL,
    time INTEGER NOT NULL,
    sapling_tree BLOB NOT NULL ,
    sapling_commitment_tree_size INTEGER,
    orchard_commitment_tree_size INTEGER,
    sapling_output_count INTEGER,
    orchard_action_count INTEGER);

-- Transactions
CREATE TABLE "transactions" (
    id_tx INTEGER PRIMARY KEY,
    txid BLOB NOT NULL UNIQUE,
    created TEXT,
    block INTEGER,
    mined_height INTEGER,
    tx_index INTEGER,
    expiry_height INTEGER,
    raw BLOB,
    fee INTEGER,
    target_height INTEGER,
    FOREIGN KEY (block) REFERENCES blocks(height),
    CONSTRAINT height_consistency CHECK (block IS NULL OR mined_height = block)
);

-- Sapling Received Notes
CREATE TABLE "sapling_received_notes" (
    id INTEGER PRIMARY KEY,
    tx INTEGER NOT NULL,
    output_index INTEGER NOT NULL,
    account_id INTEGER NOT NULL,
    diversifier BLOB NOT NULL,
    value INTEGER NOT NULL,
    rcm BLOB NOT NULL,
    nf BLOB UNIQUE,
    is_change INTEGER NOT NULL,
    memo BLOB,
    commitment_tree_position INTEGER,
    recipient_key_scope INTEGER,
    FOREIGN KEY (tx) REFERENCES transactions(id_tx),
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    CONSTRAINT tx_output UNIQUE (tx, output_index)
);

CREATE INDEX "sapling_received_notes_account" ON "sapling_received_notes" (
    "account_id" ASC
);
CREATE INDEX "sapling_received_notes_tx" ON "sapling_received_notes" (
    "tx" ASC
);

-- Sapling Received Note Spends
CREATE TABLE sapling_received_note_spends (
    sapling_received_note_id INTEGER NOT NULL,
    transaction_id INTEGER NOT NULL,
    FOREIGN KEY (sapling_received_note_id)
        REFERENCES sapling_received_notes(id)
        ON DELETE CASCADE,
    FOREIGN KEY (transaction_id)
        -- We do not delete transactions, so this does not cascade
        REFERENCES transactions(id_tx),
    UNIQUE (sapling_received_note_id, transaction_id)
);

-- Orchard Received Notes
CREATE TABLE orchard_received_notes (
    id INTEGER PRIMARY KEY,
    tx INTEGER NOT NULL,
    action_index INTEGER NOT NULL,
    account_id INTEGER NOT NULL,
    diversifier BLOB NOT NULL,
    value INTEGER NOT NULL,
    rho BLOB NOT NULL,
    rseed BLOB NOT NULL,
    nf BLOB UNIQUE,
    is_change INTEGER NOT NULL,
    memo BLOB,
    commitment_tree_position INTEGER,
    recipient_key_scope INTEGER,
    FOREIGN KEY (tx) REFERENCES transactions(id_tx),
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    CONSTRAINT tx_output UNIQUE (tx, action_index)
);

CREATE INDEX orchard_received_notes_account ON orchard_received_notes (
    account_id ASC
);
CREATE INDEX orchard_received_notes_tx ON orchard_received_notes (
    tx ASC
);

-- Orchard Received Note Spends
CREATE TABLE orchard_received_note_spends (
    orchard_received_note_id INTEGER NOT NULL,
    transaction_id INTEGER NOT NULL,
    FOREIGN KEY (orchard_received_note_id)
        REFERENCES orchard_received_notes(id)
        ON DELETE CASCADE,
    FOREIGN KEY (transaction_id)
        -- We do not delete transactions, so this does not cascade
        REFERENCES transactions(id_tx),
    UNIQUE (orchard_received_note_id, transaction_id)
);

-- Transparent Received Outputs
CREATE TABLE transparent_received_outputs (
    id INTEGER PRIMARY KEY,
    transaction_id INTEGER NOT NULL,
    output_index INTEGER NOT NULL,
    account_id INTEGER NOT NULL,
    address TEXT NOT NULL,
    script BLOB NOT NULL,
    value_zat INTEGER NOT NULL,
    max_observed_unspent_height INTEGER,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id_tx),
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    CONSTRAINT transparent_output_unique UNIQUE (transaction_id, output_index)
);

CREATE INDEX idx_transparent_received_outputs_account_id
ON "transparent_received_outputs" (account_id);

-- Transparent Received Output Spends
CREATE TABLE "transparent_received_output_spends" (
    transparent_received_output_id INTEGER NOT NULL,
    transaction_id INTEGER NOT NULL,
    FOREIGN KEY (transparent_received_output_id)
        REFERENCES transparent_received_outputs(id)
        ON DELETE CASCADE,
    FOREIGN KEY (transaction_id)
        -- We do not delete transactions, so this does not cascade
        REFERENCES transactions(id_tx),
    UNIQUE (transparent_received_output_id, transaction_id)
);

-- Transparent Spend Map
CREATE TABLE transparent_spend_map (
    spending_transaction_id INTEGER NOT NULL,
    prevout_txid BLOB NOT NULL,
    prevout_output_index INTEGER NOT NULL,
    FOREIGN KEY (spending_transaction_id) REFERENCES transactions(id_tx)
    -- NOTE: We can't create a unique constraint on just (prevout_txid, prevout_output_index)
    -- because the same output may be attempted to be spent in multiple transactions, even
    -- though only one will ever be mined.
    CONSTRAINT transparent_spend_map_unique UNIQUE (
        spending_transaction_id, prevout_txid, prevout_output_index
    )
);

-- Sent Notes
CREATE TABLE "sent_notes" (
    id INTEGER PRIMARY KEY,
    tx INTEGER NOT NULL,
    output_pool INTEGER NOT NULL,
    output_index INTEGER NOT NULL,
    from_account_id INTEGER NOT NULL,
    to_address TEXT,
    to_account_id INTEGER,
    value INTEGER NOT NULL,
    memo BLOB,
    FOREIGN KEY (tx) REFERENCES transactions(id_tx),
    FOREIGN KEY (from_account_id) REFERENCES accounts(id),
    FOREIGN KEY (to_account_id) REFERENCES accounts(id),
    CONSTRAINT tx_output UNIQUE (tx, output_pool, output_index),
    CONSTRAINT note_recipient CHECK (
        (to_address IS NOT NULL) OR (to_account_id IS NOT NULL)
    )
);

CREATE INDEX sent_notes_from_account ON "sent_notes" (from_account_id);
CREATE INDEX sent_notes_to_account ON "sent_notes" (to_account_id);
CREATE INDEX sent_notes_tx ON "sent_notes" (tx);

-- Tx Retrieval Queue
CREATE TABLE tx_retrieval_queue (
    txid BLOB NOT NULL UNIQUE,
    query_type INTEGER NOT NULL,
    dependent_transaction_id INTEGER,
    FOREIGN KEY (dependent_transaction_id) REFERENCES transactions(id_tx)
);

-- Transparent Spend Search Queue
CREATE TABLE transparent_spend_search_queue (
    address TEXT NOT NULL,
    transaction_id INTEGER NOT NULL,
    output_index INTEGER NOT NULL,
    FOREIGN KEY (transaction_id) REFERENCES transactions(id_tx),
    CONSTRAINT value_received_height UNIQUE (transaction_id, output_index)
);

-- Sapling Tree Shards
CREATE TABLE sapling_tree_shards (
    shard_index INTEGER PRIMARY KEY,
    subtree_end_height INTEGER,
    root_hash BLOB,
    shard_data BLOB,
    contains_marked INTEGER,
    CONSTRAINT root_unique UNIQUE (root_hash)
);

-- Sapling Tree Cap
CREATE TABLE sapling_tree_cap (
    -- cap_id exists only to be able to take advantage of `ON CONFLICT`
    -- upsert functionality; the table will only ever contain one row
    cap_id INTEGER PRIMARY KEY,
    cap_data BLOB NOT NULL
);

-- Sapling Tree Checkpoints
CREATE TABLE sapling_tree_checkpoints (
    checkpoint_id INTEGER PRIMARY KEY,
    position INTEGER
);

-- Sapling Tree Checkpoint Marks Removed
CREATE TABLE sapling_tree_checkpoint_marks_removed (
    checkpoint_id INTEGER NOT NULL,
    mark_removed_position INTEGER NOT NULL,
    FOREIGN KEY (checkpoint_id) REFERENCES sapling_tree_checkpoints(checkpoint_id)
    ON DELETE CASCADE,
    CONSTRAINT spend_position_unique UNIQUE (checkpoint_id, mark_removed_position)
);

-- Orchard Tree Shards
CREATE TABLE orchard_tree_shards (
    shard_index INTEGER PRIMARY KEY,
    subtree_end_height INTEGER,
    root_hash BLOB,
    shard_data BLOB,
    contains_marked INTEGER,
    CONSTRAINT root_unique UNIQUE (root_hash)
);

-- Orchard Tree Cap
CREATE TABLE orchard_tree_cap (
    -- cap_id exists only to be able to take advantage of `ON CONFLICT`
    -- upsert functionality; the table will only ever contain one row
    cap_id INTEGER PRIMARY KEY,
    cap_data BLOB NOT NULL
);

-- Orchard Tree Checkpoints
CREATE TABLE orchard_tree_checkpoints (
    checkpoint_id INTEGER PRIMARY KEY,
    position INTEGER
);

-- Orchard Tree Checkpoint Marks Removed
CREATE TABLE orchard_tree_checkpoint_marks_removed (
    checkpoint_id INTEGER NOT NULL,
    mark_removed_position INTEGER NOT NULL,
    FOREIGN KEY (checkpoint_id) REFERENCES orchard_tree_checkpoints(checkpoint_id)
    ON DELETE CASCADE,
    CONSTRAINT spend_position_unique UNIQUE (checkpoint_id, mark_removed_position)
);

-- Scan Queue
CREATE TABLE scan_queue (
    block_range_start INTEGER NOT NULL,
    block_range_end INTEGER NOT NULL,
    priority INTEGER NOT NULL,
    CONSTRAINT range_start_uniq UNIQUE (block_range_start),
    CONSTRAINT range_end_uniq UNIQUE (block_range_end),
    CONSTRAINT range_bounds_order CHECK (
        block_range_start < block_range_end
    )
);

-- Tx Locator Map
CREATE TABLE tx_locator_map (
    block_height INTEGER NOT NULL,
    tx_index INTEGER NOT NULL,
    txid BLOB NOT NULL UNIQUE,
    PRIMARY KEY (block_height, tx_index)
);

-- Nullifier Map
CREATE TABLE nullifier_map (
    spend_pool INTEGER NOT NULL,
    nf BLOB NOT NULL,
    block_height INTEGER NOT NULL,
    tx_index INTEGER NOT NULL,
    CONSTRAINT tx_locator
        FOREIGN KEY (block_height, tx_index)
        REFERENCES tx_locator_map(block_height, tx_index)
        ON DELETE CASCADE
        ON UPDATE RESTRICT,
    CONSTRAINT nf_uniq UNIQUE (spend_pool, nf)
);

CREATE INDEX nf_map_locator_idx ON nullifier_map(block_height, tx_index);

-------------------------
-------------------------
---- INTERNAL TABLES ----
-------------------------
-------------------------

-- schemer_migrations
CREATE TABLE schemer_migrations (
    id blob PRIMARY KEY
);

-- sqlite_sequence
CREATE TABLE sqlite_sequence(name,seq)

-------------------------
-------------------------
--------- VIEWS ---------
-------------------------
-------------------------

-- Received Outputs
CREATE VIEW v_received_outputs AS
    SELECT
        sapling_received_notes.id AS id_within_pool_table,
        sapling_received_notes.tx AS transaction_id,
        2 AS pool,
        sapling_received_notes.output_index,
        account_id,
        sapling_received_notes.value,
        is_change,
        sapling_received_notes.memo,
        sent_notes.id AS sent_note_id
    FROM sapling_received_notes
    LEFT JOIN sent_notes
    ON (sent_notes.tx, sent_notes.output_pool, sent_notes.output_index) =
       (sapling_received_notes.tx, 2, sapling_received_notes.output_index)
UNION
    SELECT
        orchard_received_notes.id AS id_within_pool_table,
        orchard_received_notes.tx AS transaction_id,
        3 AS pool,
        orchard_received_notes.action_index AS output_index,
        account_id,
        orchard_received_notes.value,
        is_change,
        orchard_received_notes.memo,
        sent_notes.id AS sent_note_id
    FROM orchard_received_notes
    LEFT JOIN sent_notes
    ON (sent_notes.tx, sent_notes.output_pool, sent_notes.output_index) =
       (orchard_received_notes.tx, 3, orchard_received_notes.action_index)
UNION
    SELECT
        u.id AS id_within_pool_table,
        u.transaction_id,
        0 AS pool,
        u.output_index,
        u.account_id,
        u.value_zat AS value,
        0 AS is_change,
        NULL AS memo,
        sent_notes.id AS sent_note_id
    FROM transparent_received_outputs u
    LEFT JOIN sent_notes
    ON (sent_notes.tx, sent_notes.output_pool, sent_notes.output_index) =
       (u.transaction_id, 0, u.output_index);

-- Received Output Spends
CREATE VIEW v_received_output_spends AS
SELECT
    2 AS pool,
    sapling_received_note_id AS received_output_id,
    transaction_id
FROM sapling_received_note_spends
UNION
SELECT
    3 AS pool,
    orchard_received_note_id AS received_output_id,
    transaction_id
FROM orchard_received_note_spends
UNION
SELECT
    0 AS pool,
    transparent_received_output_id AS received_output_id,
    transaction_id
FROM transparent_received_output_spends;

-- Transactions
CREATE VIEW v_transactions AS
WITH
notes AS (
    -- Outputs received in this transaction
    SELECT ro.account_id              AS account_id,
           transactions.mined_height  AS mined_height,
           transactions.txid          AS txid,
           ro.pool                    AS pool,
           id_within_pool_table,
           ro.value                   AS value,
           0                          AS spent_note_count,
           CASE
                WHEN ro.is_change THEN 1
                ELSE 0
           END AS change_note_count,
           CASE
                WHEN ro.is_change THEN 0
                ELSE 1
           END AS received_count,
           CASE
             WHEN (ro.memo IS NULL OR ro.memo = X'F6')
               THEN 0
             ELSE 1
           END AS memo_present,
           -- The wallet cannot receive transparent outputs in shielding transactions.
           CASE
             WHEN ro.pool = 0
               THEN 1
             ELSE 0
           END AS does_not_match_shielding
    FROM v_received_outputs ro
    JOIN transactions
         ON transactions.id_tx = ro.transaction_id
    UNION
    -- Outputs spent in this transaction
    SELECT ro.account_id              AS account_id,
           transactions.mined_height  AS mined_height,
           transactions.txid          AS txid,
           ro.pool                    AS pool,
           id_within_pool_table,
           -ro.value                  AS value,
           1                          AS spent_note_count,
           0                          AS change_note_count,
           0                          AS received_count,
           0                          AS memo_present,
           -- The wallet cannot spend shielded outputs in shielding transactions.
           CASE
             WHEN ro.pool != 0
               THEN 1
             ELSE 0
           END AS does_not_match_shielding
    FROM v_received_outputs ro
    JOIN v_received_output_spends ros
         ON ros.pool = ro.pool
         AND ros.received_output_id = ro.id_within_pool_table
    JOIN transactions
         ON transactions.id_tx = ros.transaction_id
),
-- Obtain a count of the notes that the wallet created in each transaction,
-- not counting change notes.
sent_note_counts AS (
    SELECT sent_notes.from_account_id     AS account_id,
           transactions.txid              AS txid,
           COUNT(DISTINCT sent_notes.id)  AS sent_notes,
           SUM(
             CASE
               WHEN (sent_notes.memo IS NULL OR sent_notes.memo = X'F6' OR ro.transaction_id IS NOT NULL)
                 THEN 0
               ELSE 1
             END
           ) AS memo_count
    FROM sent_notes
    JOIN transactions
         ON transactions.id_tx = sent_notes.tx
    LEFT JOIN v_received_outputs ro
         ON sent_notes.id = ro.sent_note_id
    WHERE COALESCE(ro.is_change, 0) = 0
    GROUP BY account_id, txid
),
blocks_max_height AS (
    SELECT MAX(blocks.height) AS max_height FROM blocks
)
SELECT accounts.uuid                AS account_uuid,
       notes.mined_height           AS mined_height,
       notes.txid                   AS txid,
       transactions.tx_index        AS tx_index,
       transactions.expiry_height   AS expiry_height,
       transactions.raw             AS raw,
       SUM(notes.value)             AS account_balance_delta,
       transactions.fee             AS fee_paid,
       SUM(notes.change_note_count) > 0  AS has_change,
       MAX(COALESCE(sent_note_counts.sent_notes, 0))  AS sent_note_count,
       SUM(notes.received_count)         AS received_note_count,
       SUM(notes.memo_present) + MAX(COALESCE(sent_note_counts.memo_count, 0)) AS memo_count,
       blocks.time                       AS block_time,
       (
            blocks.height IS NULL
            AND transactions.expiry_height BETWEEN 1 AND blocks_max_height.max_height
       ) AS expired_unmined,
       SUM(notes.spent_note_count) AS spent_note_count,
       (
            -- All of the wallet-spent and wallet-received notes are consistent with a
            -- shielding transaction.
            SUM(notes.does_not_match_shielding) = 0
            -- The transaction contains at least one wallet-spent output.
            AND SUM(notes.spent_note_count) > 0
            -- The transaction contains at least one wallet-received note.
            AND (SUM(notes.received_count) + SUM(notes.change_note_count)) > 0
            -- We do not know about any external outputs of the transaction.
            AND MAX(COALESCE(sent_note_counts.sent_notes, 0)) = 0
       ) AS is_shielding
FROM notes
LEFT JOIN accounts ON accounts.id = notes.account_id
LEFT JOIN transactions
     ON notes.txid = transactions.txid
JOIN blocks_max_height
LEFT JOIN blocks ON blocks.height = notes.mined_height
LEFT JOIN sent_note_counts
     ON sent_note_counts.account_id = notes.account_id
     AND sent_note_counts.txid = notes.txid
GROUP BY notes.account_id, notes.txid;

-- Tx Outputs
CREATE VIEW v_tx_outputs AS
WITH unioned AS (
    -- select all outputs received by the wallet
    SELECT transactions.txid            AS txid,
           ro.pool                      AS output_pool,
           ro.output_index              AS output_index,
           from_account.uuid            AS from_account_uuid,
           to_account.uuid              AS to_account_uuid,
           NULL                         AS to_address,
           ro.value                     AS value,
           ro.is_change                 AS is_change,
           ro.memo                      AS memo
    FROM v_received_outputs ro
    JOIN transactions
        ON transactions.id_tx = ro.transaction_id
    -- join to the sent_notes table to obtain `from_account_id`
    LEFT JOIN sent_notes ON sent_notes.id = ro.sent_note_id
    -- join on the accounts table to obtain account UUIDs
    LEFT JOIN accounts from_account ON from_account.id = sent_notes.from_account_id
    LEFT JOIN accounts to_account ON to_account.id = ro.account_id
    UNION ALL
    -- select all outputs sent from the wallet to external recipients
    SELECT transactions.txid            AS txid,
           sent_notes.output_pool       AS output_pool,
           sent_notes.output_index      AS output_index,
           from_account.uuid            AS from_account_uuid,
           NULL                         AS to_account_uuid,
           sent_notes.to_address        AS to_address,
           sent_notes.value             AS value,
           0                            AS is_change,
           sent_notes.memo              AS memo
    FROM sent_notes
    JOIN transactions
        ON transactions.id_tx = sent_notes.tx
    LEFT JOIN v_received_outputs ro ON ro.sent_note_id = sent_notes.id
    -- join on the accounts table to obtain account UUIDs
    LEFT JOIN accounts from_account ON from_account.id = sent_notes.from_account_id
)
-- merge duplicate rows while retaining maximum information
SELECT
    txid,
    output_pool,
    output_index,
    max(from_account_uuid) AS from_account_uuid,
    max(to_account_uuid) AS to_account_uuid,
    max(to_address) AS to_address,
    max(value) AS value,
    max(is_change) AS is_change,
    max(memo) AS memo
FROM unioned
GROUP BY txid, output_pool, output_index;

-- Sapling Shard Scan Ranges
CREATE VIEW v_sapling_shard_scan_ranges AS
SELECT
    shard.shard_index,
    shard.shard_index << 16 AS start_position,
    (shard.shard_index + 1) << 16 AS end_position_exclusive,
    IFNULL(prev_shard.subtree_end_height, {}) AS subtree_start_height,
    shard.subtree_end_height,
    shard.contains_marked,
    scan_queue.block_range_start,
    scan_queue.block_range_end,
    scan_queue.priority
FROM sapling_tree_shards shard
LEFT OUTER JOIN sapling_tree_shards prev_shard
    ON shard.shard_index = prev_shard.shard_index + 1
-- Join with scan ranges that overlap with the subtree's involved blocks.
INNER JOIN scan_queue ON (
    subtree_start_height < scan_queue.block_range_end AND
    (
        scan_queue.block_range_start <= shard.subtree_end_height OR
        shard.subtree_end_height IS NULL
    )
);

-- Sapling Shard Unscanned Ranges
CREATE VIEW v_sapling_shard_unscanned_ranges AS
WITH wallet_birthday AS (SELECT MIN(birthday_height) AS height FROM accounts)
SELECT
    shard_index,
    start_position,
    end_position_exclusive,
    subtree_start_height,
    subtree_end_height,
    contains_marked,
    block_range_start,
    block_range_end,
    priority
FROM v_sapling_shard_scan_ranges
INNER JOIN wallet_birthday
WHERE priority > {}
AND block_range_end > wallet_birthday.height;

-- Sapling Shards Scan State
CREATE VIEW v_sapling_shards_scan_state AS
SELECT
    shard_index,
    start_position,
    end_position_exclusive,
    subtree_start_height,
    subtree_end_height,
    contains_marked,
    MAX(priority) AS max_priority
FROM v_sapling_shard_scan_ranges
GROUP BY
    shard_index,
    start_position,
    end_position_exclusive,
    subtree_start_height,
    subtree_end_height,
    contains_marked;

-- Orchard Shard Scan Ranges
CREATE VIEW v_orchard_shard_scan_ranges AS
SELECT
    shard.shard_index,
    shard.shard_index << 16 AS start_position,
    (shard.shard_index + 1) << 16 AS end_position_exclusive,
    IFNULL(prev_shard.subtree_end_height, {}) AS subtree_start_height,
    shard.subtree_end_height,
    shard.contains_marked,
    scan_queue.block_range_start,
    scan_queue.block_range_end,
    scan_queue.priority
FROM orchard_tree_shards shard
LEFT OUTER JOIN orchard_tree_shards prev_shard
    ON shard.shard_index = prev_shard.shard_index + 1
-- Join with scan ranges that overlap with the subtree's involved blocks.
INNER JOIN scan_queue ON (
    subtree_start_height < scan_queue.block_range_end AND
    (
        scan_queue.block_range_start <= shard.subtree_end_height OR
        shard.subtree_end_height IS NULL
    )
);

-- Orchard Shard Unscanned Ranges
CREATE VIEW v_orchard_shard_unscanned_ranges AS
WITH wallet_birthday AS (SELECT MIN(birthday_height) AS height FROM accounts)
SELECT
    shard_index,
    start_position,
    end_position_exclusive,
    subtree_start_height,
    subtree_end_height,
    contains_marked,
    block_range_start,
    block_range_end,
    priority
FROM v_orchard_shard_scan_ranges
INNER JOIN wallet_birthday
WHERE priority > {}
AND block_range_end > wallet_birthday.height;

-- Orchard Shards Scan State
CREATE VIEW v_orchard_shards_scan_state AS
SELECT
    shard_index,
    start_position,
    end_position_exclusive,
    subtree_start_height,
    subtree_end_height,
    contains_marked,
    MAX(priority) AS max_priority
FROM v_orchard_shard_scan_ranges
GROUP BY
    shard_index,
    start_position,
    end_position_exclusive,
    subtree_start_height,
    subtree_end_height,
    contains_marked;

