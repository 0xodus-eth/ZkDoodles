// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Mixer} from "src/Mixer.sol";
import {HonkVerifier} from "src/Verifier.sol";
import {IncrementalMerkleTree, Poseidon2} from "src/IncrementalMerkleTree.sol";
import {Test, console} from "forge-std/Test.sol";

contract MixerTest is Test {
    Mixer public mixer;
    HonkVerifier public verifier;
    Poseidon2 public hasher;

    address public recipient = makeAddr("recipient");

    function setUp() public {
        // deploy the verifier
        verifier = new HonkVerifier();

        // deploy the hasher contracts
        hasher = new Poseidon2();

        // Deploy the mixer
        mixer = new Mixer(verifier, hasher, 20);
    }

    function _getCommitment() public returns (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) {
        // we'll use ffi in cli to create commitment
        string[] memory inputs = new string[](3);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateCommitment.ts";
        bytes memory result = vm.ffi(inputs);
        (_commitment, _nullifier, _secret) = abi.decode(result, (bytes32, bytes32, bytes32));
        return (_commitment, _nullifier, _secret);
    }

    function _getProof(bytes32 _nullifier, bytes32 _secret, address _recipient, bytes32[] memory _leaves)
        public
        returns (bytes memory proof, bytes32[] memory publicInputs)
    {
        // we'll use ffi in cli to create proof
        string[] memory inputs = new string[](6 + _leaves.length);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateProof.ts";
        inputs[3] = vm.toString(_nullifier);
        inputs[4] = vm.toString(_secret);
        inputs[5] = vm.toString(bytes32(uint256(uint160(_recipient))));

        for (uint256 i; i < _leaves.length; i++) {
            inputs[6 + i] = vm.toString(_leaves[i]);
        }
        bytes memory result = vm.ffi(inputs);
        // decode the result
        (proof, publicInputs) = abi.decode(result, (bytes, bytes32[]));
        return (proof, publicInputs);
    }

    function testMakeDeposit() public {
        // Create a commitment
        (bytes32 _commitment,,) = _getCommitment();
        // make a deposit

        console.log("Deposit made with commitment:");
        console.logBytes32(_commitment);
        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);
    }

    function testMakeWithdrawal() public {
        // make a deposit
        (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) = _getCommitment();
        console.log("Deposit made with commitment:");
        console.logBytes32(_commitment);

        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);

        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _commitment;

        // Create a Proof
        (bytes memory _proof, bytes32[] memory _publicInputs) = _getProof(_nullifier, _secret, recipient, leaves);
        // console.log("Proof generated for withdrawal:");
        // console.logBytes(_proof);
        assertTrue(verifier.verify(_proof, _publicInputs));

        // Make a withdrawal
        assertEq(recipient.balance, 0);

        mixer.withdraw(_proof, _publicInputs[0], _publicInputs[1], payable(address(uint160(uint256(_publicInputs[2])))));
        assertEq(recipient.balance, mixer.DENOMINATION());
        assertEq(address(mixer).balance, 0);
    }

    function testAnotherAddressSendProof() public {
        // make a deposit
        (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) = _getCommitment();
        console.log("Commitment: ");
        console.logBytes32(_commitment);
        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0, block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);

        // create a proof
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _commitment;
        (bytes memory _proof, bytes32[] memory _publicInputs) = _getProof(_nullifier, _secret, recipient, leaves);

        // make a withdrawal
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert();
        mixer.withdraw(_proof, _publicInputs[0], _publicInputs[1], payable(attacker));
    }
}
