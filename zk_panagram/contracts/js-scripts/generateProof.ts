import { Noir} from "@noir-lang/noir_js";
import {ethers} from "ethers";
import { UltraHonkBackend} from "@aztec/bb.js";
import { fileURLToPath } from "url";
import path from "path";
import fs from "fs";

// path.dirname(fileURLToPath(import.meta.url))
// "../../circuits/target/zk_panagram.json"

const circuitPath = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../circuits/target/zk_panagram.json");

const circuit = JSON.parse(fs.readFileSync(circuitPath, "utf8"));

export default async function generateProof() {
    const inputsArray = process.argv.slice(2);
    try {
        const noir = new Noir(circuit);
        // backed initilaization using the circuit bytecode
        const bb = new UltraHonkBackend(circuit.bytecode, {threads: 1});

        const inputs = {
            // private inputs
            guess_hash: inputsArray[0],
            // public inputs
            answer_double_hash: inputsArray[1],
            address: inputsArray[2]
        };

        const { witness} = await noir.execute(inputs);
        // generate the proof (using the backend) with the witness
        const originalConsoleLog = console.log;
        console.log = () => {}; // Suppress console.log in the backend
        const {proof} = await bb.generateProof(witness, {keccak: true});
        console.log = originalConsoleLog; // Restore console.log
        // ABI Encode the proof to a format that can be used in the test
        const proofEncoded = ethers.AbiCoder.defaultAbiCoder().encode(
            ["bytes"],
            [proof]
        )
        return proofEncoded;

    } catch (error) {
        console.log(error);
        throw error;
    }

}
(async () => {
    generateProof()
        .then((proof) => {
            process.stdout.write(proof);
            process.exit(0);
        })
        .catch((error) => {
            console.log(error);
            process.exit(1);
        });
        
})();