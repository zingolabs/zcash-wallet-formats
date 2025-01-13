# Comments taken from various places

## Zecwallet

> The account index. ZWL increments it for every new shielded address

## YWallet

> subaccounts are indeed using different a different index under the same seed.
>
> The decision to make accounts in Ywallet use a separate seed phrase was taken early. The reasons are:
>
> - Synchronization is costly. 2 accounts take ~2x longer to sync than 1. I wanted to encourage the usage of diversified addresses vs the creation of more accounts. Most users come from a background of Bitcoin where address creation has little perf impact.
> - It is possible to backup the seed phrase and be 100% guaranteed to restore in another app. With account indices, the user has to write down the account index as well.
>
> Some users disliked the approach taken by Ywallet and wanted the zcashd/zec wallet lite model but I feel vindicated when the spam hit. These users had dozens if not hundreds of accounts in their wallet. A few of them lost their funds.

> Sub-accounts share the same seed phrase but use a different derivation path. It is an advanced feature that I do not recommend using if you are not experienced.

## Zenith

> For Zenith, we would need at least the seed phrase and the birthday height.
> It would be great if the format included a list of derived accounts and the indices of the
> addresses that have been derived for each account, including change addresses.
