# Notes

## What things have happened related to zecwallet

fullnode
lite
light-cli

## The bip39 bug

It incorrectly derived HD wallet keys after the first key. That is, the first key, address was correct, but subsequent ones were not.

This was fixed automatically in the next Zecwallet(-light-cli?) release. Funds were swept automatically.

## Derivation bug

It later used a custom path.

- Was it only for legacy keys?
- New addresses were created at a different index (is this the custom path?).

## Sandblast

- What caused this spam?
- How did wallets respond?
- Is it possible that the response to this is causing funds not being shown in some wallets?

No, no and no

## Proportional Fee Transfer Mechanism

- Is it possible this affects older wallets?
- Old transaction formats (previous to v5, Orchard)

No

> Future wallet best practices will include the prevention of the creation of values < 0.00005 ( and > 0), at least while the current base fee values apply. It would probably be helpful to you to see the addresses on an explorer and get an idea of these values and whether or not they can be considered worth recovery. The issue of notes of micro-quantities being lost after the new fee structure goes into full effect has been long foreseen, with the idea of some method of sweeping these funds probably needing to be developed (after the creation of sub-par values is prevented).

transparent key stored in the wallet, derivation from seed phrase

### ZECWallet

44' / coin_type' / account' / scope [hardcoded to 0] => ES_KEY (NEW ADDRESSES ARE DERIVED FROM THIS KEY)

Example:
ES_KEY (pubkey) / i (index) => I_ADDRESS

### LRZ

44' / coin_type' / account' => AL_KEY (NEW ADDRESSES ARE DERIVED FROM THIS KEY)

Example:
AL_KEY / scope (0, 1 or 2) / i (index) => address

THE DERIVATION DID NOT CHANGE
the difference is the level of derivation where the key is stored

The following snippet was taken from the `get_taddr_from_bip39seed` in `lib/src/lightwallet/wallettkeys.rs#L50`.

```rust
pub fn get_taddr_from_bip39seed<P: consensus::Parameters>(
    config: &LightClientConfig<P>,
    bip39_seed: &[u8],
    pos: u32,
) -> secp256k1::SecretKey {
    assert_eq!(bip39_seed.len(), 64);

    let ext_t_key = ExtendedPrivKey::with_seed(bip39_seed).unwrap();
    ext_t_key
        .derive_private_key(KeyIndex::hardened_from_normalize_index(44).unwrap()) // Purpose
        .unwrap()
        .derive_private_key(KeyIndex::hardened_from_normalize_index(config.get_coin_type()).unwrap()) // Coin type
        .unwrap()
        .derive_private_key(KeyIndex::hardened_from_normalize_index(0).unwrap()) // Account
        .unwrap()
        .derive_private_key(KeyIndex::Normal(0)) // Scope, always 0 (external)
        .unwrap()
        .derive_private_key(KeyIndex::Normal(pos)) // Index
        .unwrap()
        .private_key
}
```

At some point, Zecwallet supported multi accounts?

I doubt it, but it's possible. Couldn't find it in the code.

### Potential lead

Zecwallet didn't support the canopy's v2 note plaintext format, and constructed/encoded it as pre-canopy.
Full nodes didn't reject this, but any canopy-compliant receiver wasn't able to decrypt the note correctly.
