# Backend Integration Guide for Gas Payer Contract

## Overview
The Gas Payer Contract enables your backend to fund user wallets for gas fees while collecting a service fee. Instead of sending ETH directly to users, payments go through this contract which handles fee collection automatically.

## Contract Interface

### Key Function
```solidity
function fundAndRelay(address signerAddress, uint256 gasAmount) external payable
```
- `signerAddress`: The user's wallet address that needs gas
- `gasAmount`: Amount of ETH (in wei) the user should receive for gas
- `msg.value`: Total ETH sent must equal `gasAmount + calculatedFee`

### Fee Calculation
```solidity
function calculateFee(uint256 gasAmount) public view returns (uint256)
```
Call this to determine the fee for a given gas amount before sending the transaction.

### Read-Only Properties
- `feePercentage()`: Returns fee percentage in basis points (100 = 1%)
- `minFee()`: Returns minimum fee in wei
- `feeRecipient()`: Returns address receiving fees

## Integration Steps

### 1. Contract Setup
```javascript
// Contract ABI (minimal - only what you need)
const CONTRACT_ABI = [
  {
    "inputs": [
      {"name": "signerAddress", "type": "address"},
      {"name": "gasAmount", "type": "uint256"}
    ],
    "name": "fundAndRelay",
    "type": "function",
    "stateMutability": "payable"
  },
  {
    "inputs": [
      {"name": "gasAmount", "type": "uint256"}
    ],
    "name": "calculateFee",
    "outputs": [
      {"name": "", "type": "uint256"}
    ],
    "type": "function",
    "stateMutability": "view"
  }
];

const CONTRACT_ADDRESS = "0x..."; // Will be provided after deployment
```

### 2. Web3.js Implementation
```javascript
const Web3 = require('web3');
const web3 = new Web3(process.env.RPC_URL);

// Initialize contract
const gasPayerContract = new web3.eth.Contract(CONTRACT_ABI, CONTRACT_ADDRESS);

// Your backend wallet that pays for gas
const account = web3.eth.accounts.privateKeyToAccount(process.env.BACKEND_PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);

async function fundUserGas(userAddress, gasAmountInEth) {
  try {
    // Convert ETH to wei
    const gasAmountWei = web3.utils.toWei(gasAmountInEth.toString(), 'ether');
    
    // Calculate fee
    const fee = await gasPayerContract.methods.calculateFee(gasAmountWei).call();
    
    // Total to send = gas amount + fee
    const totalAmount = BigInt(gasAmountWei) + BigInt(fee);
    
    // Send transaction
    const tx = await gasPayerContract.methods
      .fundAndRelay(userAddress, gasAmountWei)
      .send({
        from: account.address,
        value: totalAmount.toString(),
        gas: 100000 // Adjust based on network
      });
    
    console.log(`Funded ${userAddress} with ${gasAmountInEth} ETH (fee: ${web3.utils.fromWei(fee, 'ether')} ETH)`);
    console.log(`Transaction hash: ${tx.transactionHash}`);
    
    return tx.transactionHash;
  } catch (error) {
    console.error('Error funding gas:', error);
    throw error;
  }
}

// Example usage
await fundUserGas('0xUserAddress...', 0.01); // Fund with 0.01 ETH
```

### 3. Ethers.js Implementation (Alternative)
```javascript
const { ethers } = require('ethers');

// Setup
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.BACKEND_PRIVATE_KEY, provider);
const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, wallet);

async function fundUserGas(userAddress, gasAmountInEth) {
  try {
    // Convert to wei
    const gasAmountWei = ethers.parseEther(gasAmountInEth.toString());
    
    // Calculate fee
    const fee = await contract.calculateFee(gasAmountWei);
    
    // Total amount to send
    const totalAmount = gasAmountWei + fee;
    
    // Send transaction
    const tx = await contract.fundAndRelay(userAddress, gasAmountWei, {
      value: totalAmount
    });
    
    // Wait for confirmation
    const receipt = await tx.wait();
    
    console.log(`Funded ${userAddress} with ${gasAmountInEth} ETH`);
    console.log(`Transaction hash: ${receipt.hash}`);
    
    return receipt.hash;
  } catch (error) {
    console.error('Error funding gas:', error);
    throw error;
  }
}
```

## Important Notes

### Fee Structure
- The contract charges the greater of:
  - A percentage of the gas amount (e.g., 1%)
  - A minimum fee (e.g., 0.001 ETH)
- Always call `calculateFee()` first to know the exact fee

### Transaction Flow
1. Backend calls `calculateFee(gasAmount)` to get fee
2. Backend sends `gasAmount + fee` to the contract
3. Contract transfers `gasAmount` to user
4. Contract transfers `fee` to fee recipient
5. Any excess is refunded to backend

### Error Handling
The contract will revert if:
- Insufficient ETH sent (less than gasAmount + fee)
- Transfer to user fails (e.g., contract that rejects ETH)
- Transfer to fee recipient fails

### Gas Estimation
- Typical gas usage: ~50,000-70,000 gas units
- Add buffer for safety: 100,000 gas limit recommended
- Monitor actual usage and adjust accordingly

### Example Scenarios
```javascript
// Small amount - minimum fee applies
gasAmount: 0.05 ETH
fee: 0.001 ETH (minimum)
total to send: 0.051 ETH

// Large amount - percentage fee applies  
gasAmount: 1 ETH
fee: 0.01 ETH (1%)
total to send: 1.01 ETH
```

## Testing Recommendations

1. **Test on testnet first** (Base Sepolia, etc.)
2. **Start with small amounts** to verify integration
3. **Monitor events** - Contract emits `FundAndRelay` and `FeeCollected` events
4. **Handle failures gracefully** - Implement retry logic with exponential backoff

## Security Considerations

- Keep backend private key secure (use environment variables)
- The contract has no access restrictions - any address can call it
- Implement rate limiting in your backend to prevent abuse
- Monitor for unusual activity
- Consider implementing a maximum gas amount per transaction
- Log all transactions for audit purposes
- Your backend private key is separate from the deployment private key

## Contact
For contract deployment address and network-specific details, check the deployment outputs or GitHub Actions logs.