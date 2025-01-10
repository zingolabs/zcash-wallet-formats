CREATE TABLE IF NOT EXISTS schema_version (
    id INTEGER PRIMARY KEY NOT NULL,
    version INTEGER NOT NULL
);

CREATE TABLE accounts (
    id_account INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    seed TEXT,
    aindex INTEGER NOT NULL,
    sk TEXT,
    ivk TEXT NOT NULL UNIQUE,
    address TEXT NOT NULL
);

CREATE TABLE blocks (
    height INTEGER PRIMARY KEY,
    hash BLOB NOT NULL,
    timestamp INTEGER NOT NULL
);

CREATE TABLE transactions (
    id_tx INTEGER PRIMARY KEY,
    account INTEGER NOT NULL,
    txid BLOB NOT NULL,
    height INTEGER NOT NULL,
    timestamp INTEGER NOT NULL,
    value INTEGER NOT NULL,
    address TEXT,
    memo TEXT,
    tx_index INTEGER,
    messages BLOB NULL,
    CONSTRAINT tx_account UNIQUE (height, tx_index, account)
);

CREATE TABLE sapling_witnesses (
    id_witness INTEGER PRIMARY KEY,
    note INTEGER NOT NULL,
    height INTEGER NOT NULL,
    witness BLOB NOT NULL,
    CONSTRAINT witness_height UNIQUE (note, height)
);

CREATE TABLE diversifiers (
    account INTEGER PRIMARY KEY NOT NULL,
    diversifier_index BLOB NOT NULL
);

CREATE TABLE contacts (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    dirty BOOL NOT NULL
);

CREATE INDEX i_account ON accounts(address);
CREATE INDEX i_contact ON contacts(address);
CREATE INDEX i_transaction ON transactions(account);
CREATE INDEX i_witness ON sapling_witnesses(height);

CREATE TABLE messages (
    id INTEGER PRIMARY KEY,
    account INTEGER NOT NULL,
    sender TEXT,
    recipient TEXT NOT NULL,
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    timestamp INTEGER NOT NULL,
    height INTEGER NOT NULL,
    read BOOL NOT NULL,
    id_tx INTEGER,
    incoming BOOL NOT NULL DEFAULT true,
    vout INTEGER NOT NULL DEFAULT(0)
);

CREATE TABLE orchard_addrs(
    account INTEGER PRIMARY KEY,
    sk BLOB,
    fvk BLOB NOT NULL
);

CREATE TABLE ua_settings(
    account INTEGER PRIMARY KEY,
    transparent BOOL NOT NULL,
    sapling BOOL NOT NULL,
    orchard BOOL NOT NULL
);

CREATE TABLE sapling_tree(
    height INTEGER PRIMARY KEY,
    tree BLOB NOT NULL
);

CREATE TABLE orchard_tree(
    height INTEGER PRIMARY KEY,
    tree BLOB NOT NULL
);

CREATE TABLE received_notes (
    id_note INTEGER PRIMARY KEY,
    account INTEGER NOT NULL,
    position INTEGER NOT NULL,
    tx INTEGER NOT NULL,
    height INTEGER NOT NULL,
    output_index INTEGER NOT NULL,
    diversifier BLOB NOT NULL,
    value INTEGER NOT NULL,
    rcm BLOB NOT NULL,
    nf BLOB NOT NULL UNIQUE,
    rho BLOB,
    orchard BOOL NOT NULL DEFAULT false,
    spent INTEGER,
    excluded BOOL,
    CONSTRAINT tx_output UNIQUE (tx, orchard, output_index)
);

CREATE TABLE orchard_witnesses (
    id_witness INTEGER PRIMARY KEY,
    note INTEGER NOT NULL,
    height INTEGER NOT NULL,
    witness BLOB NOT NULL,
    CONSTRAINT witness_height UNIQUE (note, height)
);

CREATE INDEX i_orchard_witness ON orchard_witnesses(height);

CREATE TABLE send_templates (
    id_send_template INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    address TEXT NOT NULL,
    amount INTEGER NOT NULL,
    fiat_amount DECIMAL NOT NULL,
    fee_included BOOL NOT NULL,
    fiat TEXT,
    include_reply_to BOOL NOT NULL,
    subject TEXT NOT NULL,
    body TEXT NOT NULL
);

CREATE TABLE properties (
    name TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE TABLE taddrs (
    account INTEGER PRIMARY KEY NOT NULL,
    sk TEXT,
    address TEXT NOT NULL,
    balance INTEGER,
    height INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE hw_wallets(
    account INTEGER PRIMARY KEY NOT NULL,
    ledger BOOL NOT NULL
);

CREATE TABLE accounts2 (
    account INTEGER PRIMARY KEY NOT NULL,
    saved BOOL NOT NULL
);

CREATE TABLE account_properties (
    account INTEGER NOT NULL,
    name TEXT NOT NULL,
    value BLOB NOT NULL,
    PRIMARY KEY (account, name)
);

CREATE TABLE transparent_checkpoints (height INTEGER PRIMARY KEY);

CREATE TABLE block_times (
    height INTEGER PRIMARY KEY,
    timestamp INTEGER NOT NULL
);

CREATE TABLE transparent_tins (
    id_tx INTEGER NOT NULL,
    idx INTEGER NOT NULL,
    hash BLOB NOT NULL,
    vout INTEGER NOT NULL,
    PRIMARY KEY (id_tx, idx)
);

CREATE TABLE transparent_touts (
    id_tx INTEGER PRIMARY KEY,
    address TEXT NOT NULL
);

CREATE TABLE utxos (
    id_utxo INTEGER NOT NULL PRIMARY KEY,
    account INTEGER NOT NULL,
    height INTEGER NOT NULL,
    time INTEGER NOT NULL,
    txid BLOB NOT NULL,
    idx INTEGER NOT NULL,
    value INTEGER NOT NULL,
    spent INTEGER
);

CREATE TABLE swaps(
    id_swap INTEGER NOT NULL PRIMARY KEY,
    account INTEGER NOT NULL,
    provider TEXT NOT NULL,
    provider_id TEXT NOT NULL,
    timestamp INTEGER,
    from_currency TEXT NOT NULL,
    from_amount TEXT NOT NULL,
    from_address TEXT NOT NULL,
    from_image TEXT NOT NULL,
    to_currency TEXT NOT NULL,
    to_amount TEXT NOT NULL,
    to_address TEXT NOT NULL,
    to_image TEXT NOT NULL
);

CREATE TABLE tins(
    id_tin INTEGER NOT NULL PRIMARY KEY,
    account INTEGER NOT NULL,
    height INTEGER NOT NULL,
    id_tx INTEGER NOT NULL,
    vout INTEGER NOT NULL,
    value INTEGER NOT NULL,
    spent INTEGER
);

CREATE UNIQUE INDEX transactions_txid ON transactions (account, txid)