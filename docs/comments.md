# Comments taken from various places

## Zecwallet

> The account index. ZWL increments it for every new shielded address
>
> Address Index. ZWL increments it for every new transparent address. It is not used by shielded addresses

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

## Unrelated

> bridgetree was built on a slightly earlier set of ideas; it's no longer being maintained. I can describe briefly.
>
> First off, bridgetree was initially designed for in-order scanning of the chain. The idea it's based on is that you can prune the sections of the tree that don't contain your notes, and that the witnesses for each note can sort of "link up" (for a given position in the tree, the left-hand nodes in a witness for that position can be used to compute right-hand parts of the witness for a note to the left of that position, and vice versa.) This is where the name comes from; when you join the right-hand nodes of a witness with a frontier at a subsequent position, you kind of get a "bridge shape."
>
> These bridges are handy in that they're a monoid - you can add two bridges together to get a bigger bridge.
>
> The tree is maintained as a sequence of these bridges (loosely speaking), and when you want to compute the witness for a note, you concatenate the bridges to the left and that gives you the left-hand nodes of your witness, and do the same on the right, and you're done.
> About 90% of the way through the bridgetree implementation, I realized that I was being stupid: the root of a subtree is effectively a "bridge" between two precise positions in the tree. And it's just a single value, it's not a complex data structure containing multiple nodes at different positions in the tree.
> Also, those subtree roots are public information: you can just have a full node or light wallet server compute all of them, and download them.

> So, this is the insight that shardtree is based on: to compute the witness for a note, you just need the (pruned) information within the subtree where your note resides, and then all of the public subtree roots to the left and right of that subtree.
>
> This then also enables you to scan the tree in whatever order you want; you need complete (or actually, less than complete) information within a subtree where your note resides, and then a frontier close to the chain tip, and you can make a proof.
> And the vector of subtree roots is tiny - it's only slightly more than 1000 entries for the entire history of Sapling, for example.
> The other thing you can do is you can insert arbitrary frontiers into the tree to just add "half a witness". And we do this routinely as part of scanning anyway. We don't currently take full advantage of this; we require full subtrees to be scanned in order to spend the notes within them, but with a bit more bookkeeping in the wallet to keep track of where scans started and stopped, we can make it so that notes are spendable even more quickly.
