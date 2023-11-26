include "./get_merkle_root.circom";
include "../circomlib/circuits/mimc.circom";

// This circuit checks for the existence of a leaf in a Merkle tree of depth 'treeDepth'
// Adapted from: https://github.com/vaibhavchellani/RollupNC_tutorial/tree/master (Credits)

template LeafExistence(treeDepth, preimageLength) {
    // treeDepth is the depth of the Merkle tree
    // preimageLength is the length of the preimage of the leaf

    signal private input leafPreimage[preimageLength]; // Array to hold the preimage of the leaf
    signal input merkleRoot; // The root of the Merkle tree
    signal input merklePaths[treeDepth]; // Paths to the root of the Merkle tree
    signal input merklePathPositions[treeDepth]; // Positions in the paths to the root

    component leafHash = MultiMiMC7(preimageLength, 91);
    for (var i = 0; i < preimageLength; i++) {
        leafHash.in[i] <== leafPreimage[i];
    }

    component rootCalculator = GetMerkleRoot(treeDepth);
    rootCalculator.leaf <== leafHash.out;

    for (var j = 0; j < treeDepth; j++) {
        rootCalculator.merklePaths[j] <== merklePaths[j];
        rootCalculator.merklePathPositions[j] <== merklePathPositions[j];
    }

    // Constraint to ensure the computed Merkle root matches the provided root
    merkleRoot === rootCalculator.out;
}
