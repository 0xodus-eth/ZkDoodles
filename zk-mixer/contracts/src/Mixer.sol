// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IVerifier} from "src/Verifier.sol";
import {IncrementalMerkleTree, Poseidon2} from "src/IncrementalMerkleTree.sol";

/**
 * @title Mixer
 * @dev A smart contract that implements a zk mixer for private transactions.
 * It allows users to deposit Ether in a way that obscures the source of funds and withdraw
 * @author 0x
 * @notice
 */
contract Mixer is IncrementalMerkleTree {
    IVerifier public immutable i_verifier;

    // mapping
    mapping(bytes32 => bool) private s_commitments;
    mapping(bytes32 => bool) private s_nullifierHashes;

    uint256 public constant DENOMINATION = 0.001 ether;

    event Deposit(bytes32 indexed commitment, uint32 insertedIndex, uint256 timestamp);
    event Withdraw(address indexed recipient, bytes32 nullifierHash);

    error Mixer__CommitmentAlreadyAdded(bytes32 commitment);
    error Mixer__DepositAmountNotCorrect(uint256 amountSent, uint256 expected);
    error Mixer__UnknownRoot(bytes32 root);
    error Mixer__NullifierHashAlreadyUsed(bytes32 nullifierHash);
    error Mixer__InvalidProof();
    error Mixer__PaymentFailed(address recipient, bytes data);

    constructor(IVerifier _verifier, Poseidon2 _hasher, uint32 _merkleTreeDepth)
        IncrementalMerkleTree(_merkleTreeDepth, _hasher)
    {
        i_verifier = _verifier;
    }

    /// @notice Deposit Ether into the mixer
    /// @param _commitment goona use the poseiden commitment of the nullifier and secret (generated off-chain)
    function deposit(bytes32 _commitment) external payable {
        // check whether commitment has been use to avoid double deposits
        if (s_commitments[_commitment]) {
            revert Mixer__CommitmentAlreadyAdded(_commitment);
        }
        if (msg.value != DENOMINATION) {
            revert Mixer__DepositAmountNotCorrect(msg.value, DENOMINATION);
        }
        // allow user to send eth and ensure it is of the correct amount
        // add the commitement to the onchain incremental merkle tree
        uint32 insertedIndex = _insert(_commitment);
        s_commitments[_commitment] = true;
        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    /// @notice Withdraw ether from the mixer in a private way
    /// @param _proof proof that the user has the right to withdraw a certain commitment
    /// @param _root the root of the merkle tree used in the proof
    /// @param _nullifierHash the hash of the nullifier used in the proof
    /// @param _recipient the address to which the funds will be sent
    /// @dev The proof is generated off-chain using the nullifier and secret
    function withdraw(bytes memory _proof, bytes32 _root, bytes32 _nullifierHash, address _recipient) external {
        // check that the root used int the proof matches the onchain root
        if (!isKnownRoot(_root)) {
            revert Mixer__UnknownRoot(_root);
        }
        // check that proof is valid
        if (s_nullifierHashes[_nullifierHash]) {
            revert Mixer__NullifierHashAlreadyUsed(_nullifierHash);
        }
        // check that the proof is valid
        bytes32[] memory publicInputs = new bytes32[](3);
        publicInputs[0] = _root;
        publicInputs[1] = _nullifierHash;
        publicInputs[2] = bytes32(uint256(uint160(_recipient)));
        if (!i_verifier.verify(_proof, publicInputs)) {
            revert Mixer__InvalidProof();
        }
        // check the nullifier is not used to avoid double spending
        s_nullifierHashes[_nullifierHash] = true;

        (bool success, bytes memory data) = payable(_recipient).call{value: DENOMINATION}("");
        if (!success) {
            revert Mixer__PaymentFailed(_recipient, data);
        }
        emit Withdraw(_recipient, _nullifierHash);
    }
}
