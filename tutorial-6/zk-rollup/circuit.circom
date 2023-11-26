include "./check_leaf_existence.circom";
include "./verify_signature.circom";
include "./calculate_merkle_root.circom";
include "../circomlib/circuits/mimc.circom";

/*
 * ZK-Rollup Transaction Processing Circuit
 * -----------------------------------------
 * This Circom circuit, 'ProcessTransaction', is designed for ZK-Rollup based blockchain transaction processing. 
 * It verifies transactions within a Merkle Tree structure without revealing individual transaction details, 
 * maintaining both privacy and efficiency in the blockchain network.
 *
 * Functionality:
 * 1. Account Tree Verification: 
 *    - Verifies the existence of sender and receiver accounts in the Merkle Tree of account balances.
 *    - Utilizes the 'LeafExistence' subcircuit to check account presence using Merkle Proofs.
 *
 * 2. Transaction Signature Verification:
 *    - Ensures the transaction is authorized by the sender.
 *    - Uses the 'VerifySignatureWithMiMC' subcircuit for EdDSA signature verification with MiMC hashing.
 *
 * 3. Balance Update and Merkle Root Computation:
 *    - Updates account balances for both sender and receiver.
 *    - Computes new Merkle Tree roots post-transaction, reflecting the updated balances.
 *    - Employs the 'GetMerkleRoot' subcircuit to calculate new roots after debiting and crediting accounts.
 *
 * Parameters:
 * - treeDepth: Depth of the Merkle Tree representing account balances.
 * - currentAccountRoot: The current root of the account Merkle Tree.
 * - updatedAccountRoot: The intermediate root after processing the sender's transaction.
 * - accountPublicKeys, accountBalances: Public keys and balances of all accounts.
 * - senderPublicKey, senderInitialBalance, receiverPublicKey, receiverInitialBalance: 
 *   Public keys and initial balances of the transaction's sender and receiver.
 * - transferAmount: Amount to be transferred in the transaction.
 * - transactionSignatureR8x, transactionSignatureR8y, transactionSignatureS: Components of the transaction's signature.
 * - senderMerkleProof, senderProofPositions, receiverMerkleProof, receiverProofPositions: Merkle Proofs and positions for sender and receiver.
 * 
 * Output:
 * - updatedFinalAccountRoot: The final updated root of the account tree post-transaction.
 *
 * This circuit is a key component in ZK-Rollup implementation for Layer 2 scaling solutions, 
 * enabling efficient and private transactions on blockchain networks.
 *
 * Adapted from: https://github.com/vaibhavchellani/RollupNC_tutorial/tree/master (Credits)
 */

template ProcessTransaction(treeDepth) {
    // treeDepth is the depth of the account tree

    // Account tree information
    signal input currentAccountRoot; // Current root of the account tree
    signal private input updatedAccountRoot; // Updated root after processing transaction
    signal private input accountPublicKeys[2**treeDepth, 2]; // Public keys of accounts in the tree
    signal private input accountBalances[2**treeDepth]; // Balances of accounts in the tree

    // Transaction information
    signal private input senderPublicKey[2]; // Sender's public key
    signal private input senderInitialBalance; // Sender's initial balance
    signal private input receiverPublicKey[2]; // Receiver's public key
    signal private input receiverInitialBalance; // Receiver's initial balance
    signal private input transferAmount; // Amount to transfer
    signal private input transactionSignatureR8x; // X coordinate of the signature
    signal private input transactionSignatureR8y; // Y coordinate of the signature
    signal private input transactionSignatureS; // S component of the signature
    signal private input senderMerkleProof[treeDepth]; // Merkle proof for the sender
    signal private input senderProofPositions[treeDepth]; // Merkle proof positions for the sender
    signal private input receiverMerkleProof[treeDepth]; // Merkle proof for the receiver
    signal private input receiverProofPositions[treeDepth]; // Merkle proof positions for the receiver

    // Output
    signal output updatedFinalAccountRoot; // Final updated root of the account tree

    // Verify sender account existence in the account tree
    component checkSenderExistence = LeafExistence(treeDepth, 3);
    checkSenderExistence.leafPreimage[0] <== senderPublicKey[0];
    checkSenderExistence.leafPreimage[1] <== senderPublicKey[1];
    checkSenderExistence.leafPreimage[2] <== senderInitialBalance;
    checkSenderExistence.merkleRoot <== currentAccountRoot;
    for (var i = 0; i < treeDepth; i++) {
        checkSenderExistence.merklePathPositions[i] <== senderProofPositions[i];
        checkSenderExistence.merklePaths[i] <== senderMerkleProof[i];
    }

    // Verify the transaction was signed by the sender
    component checkSignature = VerifySignatureWithMiMC(5);
    checkSignature.publicKeyX <== senderPublicKey[0];
    checkSignature.publicKeyY <== senderPublicKey[1];
    checkSignature.signatureR8x <== transactionSignatureR8x;
    checkSignature.signatureR8y <== transactionSignatureR8y;
    checkSignature.signatureS <== transactionSignatureS;
    // Transaction details as preimage for the signature check
    for (var j = 0; j < 5; j++) {
        checkSignature.messageHash[j] <== j < 2 ? senderPublicKey[j] : (j < 4 ? receiverPublicKey[j - 2] : transferAmount);
    }

    // Debit sender account and compute new sender leaf hash
    component newSenderLeafHash = MultiMiMC7(3, 91);
    newSenderLeafHash.in[0] <== senderPublicKey[0];
    newSenderLeafHash.in[1] <== senderPublicKey[1];
    newSenderLeafHash.in[2] <== senderInitialBalance - transferAmount;

    // Update the account tree with the new sender leaf
    component updateSenderAccountRoot = CalculateMerkleRoot(treeDepth);
    updateSenderAccountRoot.leaf <== newSenderLeafHash.out;
    for (var k = 0; k < treeDepth; k++) {
        updateSenderAccountRoot.merklePathPositions[k] <== senderProofPositions[k];
        updateSenderAccountRoot.merklePaths[k] <== senderMerkleProof[k];
    }

    // Ensure the intermediate account root matches the computed root
    updateSenderAccountRoot.computedRoot === updatedAccountRoot;

    // Verify receiver account existence in the intermediate root
    component checkReceiverExistence = LeafExistence(treeDepth, 3);
    checkReceiverExistence.leafPreimage[0] <== receiverPublicKey[0];
    checkReceiverExistence.leafPreimage[1] <== receiverPublicKey[1];
    checkReceiverExistence.leafPreimage[2] <== receiverInitialBalance;
    checkReceiverExistence.merkleRoot <== updatedAccountRoot;
    for (var l = 0; l < treeDepth; l++) {
        checkReceiverExistence.merklePathPositions[l] <== receiverProofPositions[l];
        checkReceiverExistence.merklePaths[l] <== receiverMerkleProof[l];
    }

    // Credit receiver account and compute new receiver leaf hash
    component newReceiverLeafHash = MultiMiMC7(3, 91);
    newReceiverLeafHash.in[0] <== receiverPublicKey[0];
    newReceiverLeafHash.in[1] <== receiverPublicKey[1];
    newReceiverLeafHash.in[2] <== receiverInitialBalance + transferAmount;

    // Update the account tree with the new receiver leaf
    component updateReceiverAccountRoot = GetMerkleRoot(treeDepth);
    updateReceiverAccountRoot.leaf <== newReceiverLeafHash.out;
    for (var m = 0; m < treeDepth; m++) {
        updateReceiverAccountRoot.merklePathPositions[m] <== receiverProofPositions[m];
        updateReceiverAccountRoot.merklePaths[m] <== receiverMerkleProof[m];
    }

    // Output the final updated account root
    updatedFinalAccountRoot <== updateReceiverAccountRoot.computedRoot;
}

component main = ProcessTransaction(1);
