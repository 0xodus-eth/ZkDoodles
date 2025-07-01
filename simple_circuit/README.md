# Simple Circuit

A basic zero-knowledge proof circuit built with Noir that demonstrates inequality constraint verification.

## Overview

This project contains a simple Noir circuit that proves two field elements are not equal, without revealing the private input value.

## Circuit Logic

The circuit takes two inputs:

- `x`: A private field element (secret)
- `y`: A public field element

The circuit asserts that `x != y`, proving that the private input is different from the public value without revealing what the private input actually is.

## Project Structure

```
├── src/
│   └── main.nr          # Main circuit implementation
├── Nargo.toml           # Project configuration
├── Prover.toml          # Input values for proof generation
└── target/              # Compiled circuit and proof artifacts
```

## Configuration

The current configuration in `Prover.toml` sets:

- Private input `x = 2`
- Public input `y = 3`

You can modify these values to test different scenarios.

## Zero-Knowledge Properties

This circuit demonstrates:

- **Completeness**: Valid proofs can be generated when x ≠ y
- **Soundness**: Invalid proofs cannot be created when x = y
- **Zero-Knowledge**: The verifier learns only that x ≠ y, not the actual value of x
