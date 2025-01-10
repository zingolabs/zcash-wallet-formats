# YWallet

YWallet stores it's data in an sqlite database.

## Objects Stored

### Account

```rust
name: TEXT NOT NULL
seed: TEXT
account_index: INTEGER NOT NULL
spending_key: TEXT
incoming_viewing_key: TEXT NOT NULL UNIQUE
address: TEXT NOT NULL,
diversifiers: ARRAY(INTEGER)
```
