# YWallet

YWallet stores it's data in an sqlite database.

Here's an ER Diagram of the database schema:

![ER Diagram](./assets/images/ywallet-erd-dbvis.png)

## Objects Stored

### SchemaVersion

```rust
version INTEGER NOT NULL
```

### Account

```rust
id_account: INTEGER PK
name: TEXT NOT NULL
seed: TEXT
aindex: INTEGER NOT NULL
sk: TEXT
ivk: TEXT NOT NULL UNIQUE
address: TEXT NOT NULL,
```

### Transaction

```rust
id_tx: INTEGER PK
account: INTEGER NOT NULL // Reference to Account
txid: BLOB NOT NULL
height: INTEGER NOT NULL
timestamp: INTEGER NOT NULL
value: INTEGER NOT NULL
address: TEXT
memo: TEXT
tx_index: INTEGER
messages: BLOB
```

With:

```rust
(height, tx_index, account) UNIQUE
(account, txid) UNIQUE
```

### Block

```rust
height: INTEGER PK
hash: BLOB NOT NULL
timestamp: INTEGER NOT NULL
```

### SaplingWitness

```rust
note: INTEGER PK
height: INTEGER NOT NULL
witness: BLOB NOT NULL
```

With:

```rust
(note, height) UNIQUE
```

### OrchardWitness

```rust
id_witness: INTEGER PK
note: INTEGER NOT NULL
height: INTEGER NOT NULL
witness: BLOB NOT NULL
```

With:

```rust
(note, height) UNIQUE
```

### Diversifier

```rust
account: INTEGER NOT NULL PK
diversifier_index: BLOB NOT NULL
```

### Contact

```rust
id: INTEGER PK
name: TEXT NOT NULL
address: TEXT NOT NULL
dirty: BOOL NOT NULL
```

### Message

```rust
id: INTEGER PK
account: INTEGER NOT NULL // Reference to Account
sender: TEXT
recipient: TEXT NOT NULL
subject: TEXT NOT NULL
body: TEXT NOT NULL
timestamp: INTEGER NOT NULL
height: INTEGER NOT NULL
read: BOOL NOT NULL
id_tx: INTEGER // Reference to Transaction
incoming: BOOL NOT NULL = true
vout: INTEGER NOT NULL = 0
```

### OrchardAddr

```rust
account: INTEGER PK // Reference to Account
sk: BLOB
fvk: BLOB NOT NULL
```

### UASettings

```rust
account: INTEGER PK // Reference to Account
transparent: BOOL NOT NULL
sapling: BOOL NOT NULL
orchard: BOOL NOT NULL
```

### SaplingTree

```rust
height: INTEGER PK
tree: BLOB NOT NULL
```

### OrchardTree

```rust
height: INTEGER PK
tree: BLOB NOT NULL
```

### ReceivedNote

```rust
id_note: INTEGER PK
account: INTEGER NOT NULL // Reference to Account
position: INTEGER NOT NULL
tx: INTEGER NOT NULL // Reference to Transaction
height: INTEGER NOT NULL
output_index: INTEGER NOT NULL
diversifier: BLOB NOT NULL
value: INTEGER NOT NULL
rcm: BLOB NOT NULL
nf: BLOB NOT NULL UNIQUE
rho: BLOB
orchard: BOOL NOT NULL DEFAULT false
spent: INTEGER
excluded: BOOL
```

With:

```rust
(tx, orchard, output_index) UNIQUE
```

### SendTemplate

```rust
id_send_template: INTEGER PK
title: TEXT NOT NULL
address: TEXT NOT NULL
amount: INTEGER NOT NULL
fiat_amount: DECIMAL NOT NULL
fee_included: BOOL NOT NULL
fiat: TEXT
include_reply_to: BOOL NOT NULL
subject: TEXT NOT NULL
body: TEXT NOT NULL
```

### TAddr

```rust
account: INTEGER PK // Reference to Account
sk: TEXT
address: TEXT NOT NULL
balance: INTEGER
height: INTEGER NOT NULL DEFAULT 0
```

### HWWallet

```rust
account: INTEGER PK // Reference to Account
ledger: BOOL NOT NULL
```

### AccountProperty

```rust
account: INTEGER PK // Reference to Account
name: TEXT NOT NULL PK
value: BLOB NOT NULL
```

### TransparentCheckpoint

```rust
height: INTEGER PK
```

### BlockTime

```rust
height: INTEGER PK
timestamp: INTEGER NOT NULL
```

### TransparentTIns

```rust
id_tx: INTEGER NOT NULL PK
idx: INTEGER NOT NULL PK
hash: BLOB NOT NULL
vout: INTEGER NOT NULL
```

### TransparentTOuts

```rust
id_tx: INTEGER PK
address: TEXT NOT NULL
```

### UTXO

```rust
id_utxo: INTEGER NOT NULL PK
account: INTEGER NOT NULL // Reference to Account
height: INTEGER NOT NULL
timestamp: INTEGER NOT NULL
txid: BLOB NOT NULL // Reference to Transaction
idx: INTEGER NOT NULL
value: INTEGER NOT NULL
spent: INTEGER
```

### Swap

```rust
id_swap: INTEGER NOT NULL PK
account: INTEGER NOT NULL // Reference to Account
provider: TEXT NOT NULL
provider_id: TEXT NOT NULL
timestamp: INTEGER
from_currency: TEXT NOT NULL
from_amount: TEXT NOT NULL
from_address: TEXT NOT NULL
from_image: TEXT NOT NULL
to_currency: TEXT NOT NULL
to_amount: TEXT NOT NULL
to_address: TEXT NOT NULL
to_image: TEXT NOT NULL
```

### TIns

```rust
id_tin: INTEGER NOT NULL PK
account: INTEGER NOT NULL // Reference to Account
height: INTEGER NOT NULL
id_tx: INTEGER NOT NULL // Reference to Transaction
vout: INTEGER NOT NULL
value: INTEGER NOT NULL
spent: INTEGER
```
