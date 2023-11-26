include "../circomlib/circuits/mimc.circom";

// This circuit calculates the merkle root for the given.
// Adapted from: https://github.com/vaibhavchellani/RollupNC_tutorial/tree/master (Credits)

template CalculateMerkleRoot(treeDepth) {
    // treeDepth is the depth of the Merkle tree

    signal input leafNode; // The leaf node for which the Merkle path is computed
    signal input merklePathNodes[treeDepth]; // Array of nodes in the path to the root
    signal input merklePathPositions[treeDepth]; // Array of positions in the path (0 or 1)

    signal output computedRoot; // The computed Merkle root

    // Hashes for each level of the Merkle tree
    component merkleHashes[treeDepth];
    merkleHashes[0] = MultiMiMC7(2, 91);
    merkleHashes[0].in[0] <== merklePathNodes[0] - merklePathPositions[0] * (merklePathNodes[0] - leafNode);
    merkleHashes[0].in[1] <== leafNode - merklePathPositions[0] * (leafNode - merklePathNodes[0]);

    // Compute hashes for all other levels in the Merkle path
    for (var i = 1; i < treeDepth; i++) {
        merkleHashes[i] = MultiMiMC7(2, 91);
        merkleHashes[i].in[0] <== merklePathNodes[i] - merklePathPositions[i] * (merklePathNodes[i] - merkleHashes[i-1].out);
        merkleHashes[i].in[1] <== merkleHashes[i-1].out - merklePathPositions[i] * (merkleHashes[i-1].out - merklePathNodes[i]);
    }

    // Assign the last hash as the output, representing the computed Merkle root
    computedRoot <== merkleHashes[treeDepth-1].out;
}
