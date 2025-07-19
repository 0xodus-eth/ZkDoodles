fn main(guess_hash: Field, answer_hash: pub Field, address: pub Field) {
    let addr_pow = address.pow_32(2);
    assert(addr_pow == address.pow_32(2));
    assert(guess_hash == answer_hash);
}

// #[test]
// fn test_main() {
//     main(1, 2);

//     // Uncomment to make test fail
//     // main(1, 1);
// }
