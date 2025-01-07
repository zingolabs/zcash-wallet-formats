# Zingo & Zingolib

## Background information

Zingolib uses a bespoke format for storing wallet data on disk.

The top-level functions used to write/read wallet data is in `zingolib/src/wallet/disk.rs#48`.

## Schema (WIP)

The overall schema looks as follows:

| Keyname                  | Value              | Description                       |
| ------------------------ | ------------------ | --------------------------------- |
| Version                  | u64                |                                   |
| Keys                     |                    | Transaction Context Keys.         |
| Blocks                   | Vector<BlockData>  | Last 100 blocks, used for reorgs. |
| Transaction Metadata Set |                    |                                   |
| ChainType                | String             |                                   |
| Wallet Options           |                    |                                   |
| Birthday                 | u64                |                                   |
| Verified Tree            | Option<Vector<u8>> | Highest verified block            |
| Price                    |                    | Price information.                |
| Seed Bytes               |                    |                                   |
| Mnemonic                 | u32                | ZIP 339 mnemonic.                 |
