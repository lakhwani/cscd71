# CSCD71: BLOCKCHAINS AND DECENTRALIZED APPLICATIONS
# TUTORIAL: MULTISIGNATURE WALLETS BITCOIN SCRIPT
# Adapted from: https://github.com/wobine/blackboard101/blob/master/wbn_multisigs_pt1_create-address.py

from bitcoinrpc.authproxy import AuthServiceProxy, JSONRPCException

# Replace with your Bitcoin Core RPC configuration
rpcuser = 'x'
rpcpassword = 'x'
rpcconnect = '127.0.0.1'  # IP address of your Bitcoin Core node
rpcport = '18332'  # Port for Bitcoin Core's RPC interface

# Connect to Bitcoin Core using the configured RPC credentials
bitcoin = AuthServiceProxy(
    f'http://{rpcuser}:{rpcpassword}@{rpcconnect}:{rpcport}/wallet/walletL')

add = dict()
privkey = dict()
pubkey = dict()

bitcoin.walletpassphrase("passphrase", 100)

for i in range(0, 3):  # Generate three new addresses (Pub Key & Priv Key)
    print(f"\nBrand New Address Pair: Number {i+1}")

    add[i] = bitcoin.getnewaddress("", "legacy")
    print(f"Compressed Public Address - {len(add[i])} chars - {add[i]}")

    # This line is asking your Bitcoin Core node for the private key associated with the
    # address stored in add[i]. Since your Bitcoin Core node generated this address, it
    # knows the associated private key and can provide it.
    privkey[i] = bitcoin.dumpprivkey(add[i])
    print(f"Private Key - {len(privkey[i])} chars - {privkey[i]}")

    validDate = bitcoin.validateaddress(add[i])
    print(validDate)
    pubkey[i] = validDate["scriptPubKey"]
    print(
        f"Less compressed Public Key/Address - {len(pubkey[i])} chars - {pubkey[i]}")
