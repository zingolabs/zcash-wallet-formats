# Zcash-devtool

Zcash-devtool is able to inspect the following types:

- `bip0039::Mnemonic` (A mnemonic phrase)
- `ZcashAddress`. This includes the following addres kinds:

  - `Sprout([u8; 64])`
  - `Sapling([u8; 43])`
  - `Unified(unified::Address)`
  - `P2pkh([u8; 20])`
  - `P2sh([u8; 20])`
  - `Tex([u8; 20])`

- `Uivk` (Unified Internal Viewing Key)
- `Ufvk` (Unified Full Viewing Key)
- `Sapling Extended Full Viewing Key` (Mainnet, Testnet, Regtest)
- `Sapling Extended Spending Key` (Mainnet, Testnet, Regtest)
- **Bytes**:
  - `block::Block`
  - `BlockHeader`
  - `Transaction`
  - `TxId` (likely)
  - `Signature` (likely)
