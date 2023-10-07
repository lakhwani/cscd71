# CSCD71: BLOCKCHAINS AND DECENTRALIZED APPLICATIONS
# TUTORIAL: MULTISIGNATURE WALLETS BITCOIN SCRIPT
# Adapted from: https://github.com/wobine/blackboard101/blob/master/wbn_multisigs_pt1_create-address.py

from cryptos import Bitcoin
from bitcoinrpc.authproxy import AuthServiceProxy

# RPC:= Remote Procedure Call
# RPC allows you to interact with a running Bitcoin node (in this case, Bitcoin Core) over a network
# connection by sending commands or requests to it, and receiving responses. It's like a way for
# external programs or scripts to communicatx=e with the Bitcoin software running on your computer or a remote server.

# username and password required to authenticate and authorize access to your Bitcoin Core node via RPC
rpcuser = 'x'
rpcpassword = 'x'
# This is the IP address (or hostname) where your Bitcoin Core node is running. In this example, it's set
# to 127.0.0.1, which is the loopback address, indicating that the Bitcoin Core node is running on
# the same machine where this Python script is executed.
rpcconnect = '127.0.0.1'
# This is the port number on which the Bitcoin Core's RPC interface is listening for incoming
# connections. The default port for Bitcoin's mainnet is 8332, but for testnet
# (as indicated by the port 18332), it's usually 18332.
rpcport = '18332'

# AuthServiceProxy is a class provided by the bitcoinrpc library (Python Bitcoin RPC).
# It's used to create an object that can make RPC calls to your Bitcoin Core node.
bitcoin = AuthServiceProxy(
    f'http://{rpcuser}:{rpcpassword}@{rpcconnect}:{rpcport}/wallet/walletL')

privkey = dict()    # private keys associated with the wallet
pubkey = dict()     # public keys associated with each i-th private key
addrs = dict()      # bitcoin addresses associated with each i-th public key

# The Bitcoin object acts as a utility for performing Bitcoin-specific operations.
# It encapsulates various functionalities related to Bitcoin keys, addresses, and transactions.
c = Bitcoin(testnet=True)

# Allows us to access WalletL on local since it requires a passphrase to access.
bitcoin.walletpassphrase("passphrase", 100)

# Our generated private keys from scipt generateKeys.py:
privkey = {0: 'x',
           1: 'x',
           2: 'x'}

for i in range(0, 3):
    print(f"-- Address Pair: Number {i}")

    print(f"[{i}]: Private Key: {privkey[i]} ({len(privkey[i])} chars)")

    # Retrieves the public key from the given private key.
    pubkey[i] = c.privtopub(privkey[i])
    print(
        f"[{i}]: Public Key: {pubkey[i]} ({len(pubkey[i])} chars)")

    # Convert the public key to a Bitcoin address (testnet in this example)
    addrs[i] = c.pubtoaddr(pubkey[i])
    print(
        f"[{i}]: Public Bitcoin Address: {addrs[i]} ({len(addrs[i])} chars)")

    # Validates if the address is valid.
    validDate = bitcoin.validateaddress(addrs[i])
    print(validDate)


publicKeysMultiSig = [pubkey[0], pubkey[1], pubkey[2]]

# createmultisig creates a P2SH multisig address for use in raw transactions. It outputs
# the redeem script because you’ll need that to spend any payments sent to the P2SH address.
multisigAddrRedeem = bitcoin.createmultisig(2, publicKeysMultiSig)

# addmultisigaddress adds a P2SH multisig address to your Bitcoin Core wallet,
# allowing you to track and spend payments received by that address.
# It returns the multisignature address.
# Note that both functoins used the same OpCode (OP_CHECKMULTISIG)
multisigAddress = bitcoin.addmultisigaddress(2, publicKeysMultiSig)

# P2SH := P2SH or Pay-to-Script-Hash is a type of Bitcoin address that was introduced to the
#         Bitcoin network in 2012. P2SH addresses are structured similarly to the original Bitcoin
#         addresses, known as P2PKH (Pay-to-Public-Key-Hash), that are created by hashing a redeem script.

# The main difference between P2SH and P2PKH addresses is that P2SH addresses are created by hashing
# a redeem script, which can be thought of as coded instructions specifying how bitcoin received
# to the P2SH address can be spent in the future. This provides more complex functionality than
# P2PKH, which is created by hashing a single public key.

# P2SH is most commonly used for multisig addresses which can specify that multiple digital signatures
# are required to authorize the transaction3. To spend bitcoins sent via P2SH, the recipient must
# provide a script matching the script hash and data which makes the script evaluate to true.

# MultiSig Address: tb1qjncyk2n5qh00mtpnxuvt4x485w0vjqd7v0jwdddpz630l2rm5d7sea28he
print(
    f"\nMultisig Address [2-of-3]: {multisigAddress['address']} ({len(multisigAddress['address'])} chars)")
print(
    f"\nMultisig RedeemScript: {multisigAddrRedeem['redeemScript']} ({len(multisigAddrRedeem['redeemScript'])} chars)")

# Recipient address for transaction:
sendToAddress = 'x'

# Redeem script := is a script used to unlock bitcoin sent to a P2SH (Pay-to-Script-Hash) or P2WSH (Pay-to-Witness-Script-Hash) address.
#                  In a P2SH or P2WSH transaction, bitcoin is locked to the hash of a redeem script. This ensures that only someone
#                  who can reproduce the redeem script and add any required signatures can spend the bitcoin.

# This redeem script is used to specify the conditions that must be met to spend the bitcoins associated with it.
# In the case of a multisig wallet, these conditions usually involve requiring signatures from multiple private keys.

# When you want to spend bitcoins from a multisig wallet (or more generally, from a P2SH address), you need to provide two things in your transaction:
# 1.) An unlocking script that satisfies the conditions specified in the redeem script. For a multisig wallet, this would be the required number of signatures.
# 2.) The original redeem script itself.

# These are included in the scriptSig part of the transaction input when the transaction is signed.
# The redeem script is hashed and compared with the hash in the P2SH address as part of the transaction verification process.
# If they match and the unlocking script satisfies the conditions in the redeem script, then the transaction is considered valid.

redeemScript = multisigAddrRedeem['redeemScript']

# Amount of bitcoin to send to the sendToAddress
amount = 0.000001

# Get the unspent transactions:
# You always need a UTXO or an unspent transaction output to make a transaction.
# If you don’t have an unspent transaction output, it simply means you don’t have any Bitcoin.
unspent = bitcoin.listunspent()

# Find an unspent transaction in the multisig wallet
print("\nUnspent transactions in WalletL:")
print(unspent)

# Looking for a UTXO that matches the multisignature address, and prints it.
i = 0
for u in unspent:
    if u['address'] == multisigAddress['address']:
        utxo = u
        print("\n - UTXO Number " + str(i))
        print("UTXO txId: " + utxo["txid"])
        print("UTXO vout: " + str(utxo["vout"]))
        print("UTXO amount: " + str(utxo["amount"]))
        print("UTXO scriptPubKey: " + utxo["scriptPubKey"])


# txid: This is the transaction ID, which is a unique identifier for a Bitcoin transaction.
txId1 = "x"
# vout: This is the output index number in a transaction13. It’s short for “vector out”, and it’s used to uniquely identify an output of a transaction.
vout1 = 0
# amount: This represents the amount of Bitcoin in a transaction output.
amount1 = 0.00008000
# scriptPubKey: This is a locking script placed on the output of a Bitcoin transaction that requires certain conditions to be met in order for a recipient to spend his/her
# bitcoins45. It’s also known as PubKey Script outside of the Bitcoin code.
scriptPubKey1 = "x"

# Create a raw transaction:
raw_tx = bitcoin.createrawtransaction(
    [{'txid': txId1, 'vout': vout1}], {sendToAddress: amount})

print("\nRaw Transaction (Unsigned):")
print(raw_tx)

# Signing each raw transaction by each i-th private key:
for i in range(2):
    raw_tx = bitcoin.signrawtransactionwithkey(raw_tx, [privkey[i]], [
        {'txid': txId1, 'vout': vout1, 'scriptPubKey': scriptPubKey1,
            'amount': amount1, 'redeemScript': redeemScript}
    ])['hex']
    print("\nSigned Raw Transaction by Private Key " + str(i) + " :")
    print(raw_tx)

print("Broadcasting the signed transaction...")
# Broadcast the transaction
txid = bitcoin.sendrawtransaction(raw_tx)
print(f"Transaction broadcasted with txid {txid}")

# When you call bitcoin.sendrawtransaction(raw_tx), you’re broadcasting the raw transaction to the Bitcoin network1.
# Here’s what happens in detail:
# 1.) The raw transaction raw_tx is sent to the Bitcoin network.
# 2.) The nodes in the Bitcoin network validate the transaction1. This involves checking things like whether the transaction format is correct, whether it includes a
#     sufficient transaction fee, and whether it’s trying to spend bitcoins that exist and have not been spent yet.
# 3.) If the transaction is valid, it gets relayed to other nodes in the network1. This process continues until all nodes in the network have
#     received the transaction1.
# 4.) Eventually, a miner includes the transaction in a block, and this block gets added to the Bitcoin blockchain.
#     At this point, the transaction is considered confirmed.
