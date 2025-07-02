# ZK-ECDSA

A zero-knowledge proof circuit for verifying ECDSA signatures using Noir.

## What it does

This project implements a zero-knowledge circuit that:

- Takes an ECDSA public key (x, y coordinates), signature, and hashed message as inputs
- Verifies that the signature was created by the private key corresponding to the public key
- Proves that the recovered Ethereum address matches an expected address
- Does all this verification without revealing the actual signature or public key to verifiers

## How it works

The circuit uses the `ecrecover` function to recover an Ethereum address from:

- Public key coordinates (x, y)
- ECDSA signature (64 bytes)
- Hashed message (32 bytes)

It then asserts that the recovered address matches the expected address, ensuring the signature is valid.

## Dependencies

- [ecrecover-noir](https://github.com/colinnielsen/ecrecover-noir) - ECDSA signature recovery library for Noir

## Use Cases

- Privacy-preserving signature verification
- Proving ownership of an Ethereum address without revealing the signature
- Zero-knowledge authentication systems
