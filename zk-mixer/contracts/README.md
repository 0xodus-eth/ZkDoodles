# Zk mixer Project

- Users can deposit Eth into the mixer to break the connection bwn depositer and withdrawer
- Withdraw: Users will withdraw using a ZK proof (Noir generated offchain) of knowledge of their deposit
- We will only allow users to deposit a fiex amount of Ether (0.001 Eth)

## Proof

- calculate the commitment using the secret nullifier
- Check that the comitment is present in the merkle tree
  - Proposed root
  - Merkle proof
- Check the nullifier matches the public nullifier hash

### Private Inputs

- Secret
- Nullifier
- Merkle proof (intermediate nodes required to calculate the root)
- Bool for whether the node has an even index

### Public Inputs

- Proposed root
- Nullifier hash
