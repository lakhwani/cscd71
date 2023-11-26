include "../circomlib/circuits/eddsamimc.circom";
include "../circomlib/circuits/mimc.circom";

// This circuit verifies a signature using MiMC.
// Adapted from: https://github.com/vaibhavchellani/RollupNC_tutorial/tree/master (Credits)

template VerifySignatureWithMiMC(hashLength) {
    signal input publicKeyX; // X-coordinate of the public key
    signal input publicKeyY; // Y-coordinate of the public key
    signal input signatureR8x; // X-coordinate of R8 component of the signature
    signal input signatureR8y; // Y-coordinate of R8 component of the signature
    signal input signatureS; // S component of the signature
    signal private input messageHash[hashLength]; // Hash of the message being signed
    
    // Hash the message using MiMC
    component messageHasher = MultiMiMC7(hashLength, 91);
    for (var i = 0; i < hashLength; i++) {
        messageHasher.in[i] <== messageHash[i];
    }
    
    // EdDSA Signature Verifier
    component signatureVerifier = EdDSAMiMCVerifier();
    signatureVerifier.enabled <== 1;
    signatureVerifier.Ax <== publicKeyX;
    signatureVerifier.Ay <== publicKeyY;
    signatureVerifier.R8x <== signatureR8x;
    signatureVerifier.R8y <== signatureR8y;
    signatureVerifier.S <== signatureS;
    signatureVerifier.M <== messageHasher.out; // Output of the MiMC hash as the message input for verification
}
