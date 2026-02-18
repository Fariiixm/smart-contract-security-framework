import time
from web3 import Web3
from eth_account import Account
import json
import os

# Connect to local Anvil node
w3 = Web3(Web3.HTTPProvider('http://127.0.0.1:8545'))

if not w3.is_connected():
    print("Error: Could not connect to Anvil node at http://127.0.0.1:8545")
    exit(1)

print(f"Connected to Anvil node. Block number: {w3.eth.block_number}")

# Load the compiled contract ABI and Bytecode
# We assume the user has run `forge build` and the artifact is in `out/CalldataGas.sol/CalldataGas.json`
# If not, we might need to compile it or use solcx. 
# Since this is a Foundry project, `forge build` is the standard way.

artifact_path = os.path.join(os.path.dirname(__file__), '../out/CalldataGas.sol/CalldataGas.json')

if not os.path.exists(artifact_path):
    print(f"Error: Artifact not found at {artifact_path}. Please run `forge build` first.")
    exit(1)

with open(artifact_path, 'r') as f:
    artifact = json.load(f)

abi = artifact['abi']
bytecode = artifact['bytecode']['object']

# Set up account (Anvil default account #0)
# Private key for Account #0: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
private_key = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
account = Account.from_key(private_key)
w3.eth.default_account = account.address

print(f"Using account: {account.address}")

# Deploy contract
CalldataGas = w3.eth.contract(abi=abi, bytecode=bytecode)
construct_txn = CalldataGas.constructor().build_transaction({
    'from': account.address,
    'nonce': w3.eth.get_transaction_count(account.address),
    'gas': 2000000,
    'gasPrice': w3.to_wei('1', 'gwei')
})

signed = account.sign_transaction(construct_txn)
tx_hash = w3.eth.send_raw_transaction(signed.raw_transaction)
tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

contract_address = tx_receipt.contractAddress
print(f"Contract deployed at: {contract_address}")

contract_instance = w3.eth.contract(address=contract_address, abi=abi)

def measure_gas(val, description):
    func_call = contract_instance.functions.f(val)
    # Build transaction to send it
    tx = func_call.build_transaction({
        'from': account.address,
        'nonce': w3.eth.get_transaction_count(account.address),
        'gas': 2000000,
        'gasPrice': w3.to_wei('1', 'gwei')
    })
    
    signed_tx = account.sign_transaction(tx)
    tx_hash = w3.eth.send_raw_transaction(signed_tx.raw_transaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    
    print(f"{description}: Gas Used = {receipt.gasUsed}")
    return receipt.gasUsed

# 1. fn(0) -> 0 bytes of non-zero data (in theory)
# Solidity encoding of 0 is 32 bytes of zeros.
# 4 bytes selector + 32 bytes of zeros.
gas_0 = measure_gas(0, "f(0)")

# 2. fn(MAX_UINT) -> 32 bytes of non-zero data (0xFF...FF)
# Solidity encoding is 32 bytes of ones.
# 4 bytes selector + 32 bytes of ones.
max_uint = 2**256 - 1
gas_max = measure_gas(max_uint, "f(MAX_UINT)")

diff = gas_max - gas_0
print(f"Difference: {diff} gas")

# Expected difference:
# Each non-zero byte costs 16 gas.
# Each zero byte costs 4 gas.
# We are changing 32 bytes from 0x00 to 0xFF.
# Cost increase = 32 * (16 - 4) = 32 * 12 = 384 gas.
print(f"Expected Difference (approx): 384 gas (32 bytes * 12 gas/byte difference)")

