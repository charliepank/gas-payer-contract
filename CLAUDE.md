# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Foundry-based Solidity project for a gas payer contract that enables users to fund Ethereum transactions on behalf of signers. The project consists of:

- **GasPayerContract**: Core contract that accepts ETH payments and distributes gas amounts to target addresses while collecting a fixed 0.5 ETH fee per transaction

## Development Commands

### Building and Testing
```bash
# Build contracts
forge build

# Run all tests with verbose output
forge test -vvv

# Run specific test file
forge test --match-path test/GasPayerContract.t.sol -vvv

# Run fuzz tests (256 runs configured)
forge test --fuzz-runs 256

# Install dependencies (OpenZeppelin)
forge install OpenZeppelin/openzeppelin-contracts --shallow
```

### Environment Setup
Copy `.env.example` to `.env` and configure:
- `RELAYER_WALLET_PRIVATE_KEY`: Private key for deployment
- `FEE_RECIPIENT`: Address that will receive the fees (immutable after deployment)
- `FEE_PERCENTAGE`: Fee percentage in basis points (100 = 1%, 250 = 2.5%)
- `MIN_FEE`: Minimum fee in wei (e.g., 1000000000000000 = 0.001 ETH)
- `NETWORK_RPC_URL`: RPC endpoint for target network
- `VERIFIER_API_KEY`: API key for contract verification
- `VERIFIER_URL`: Block explorer API URL for verification

### Deployment
```bash
# Deploy to configured network with verification
forge script script/DeploymentScript.s.sol:DeploymentScript --rpc-url $NETWORK_RPC_URL --broadcast --verify --verifier blockscout --verifier-url $VERIFIER_URL -vvvv
```

## Contract Architecture

### GasPayerContract
- **Purpose**: Accepts ETH payments, transfers gas amounts to signers, collects percentage-based fees with minimum floor
- **Key Functions**:
  - `fundAndRelay(address signerAddress, uint256 gasAmount)`: Main function for gas payment with fee collection
  - `calculateFee(uint256 gasAmount)`: Returns the fee for a given gas amount (max of percentage or minimum)
- **Fee Structure**: 
  - Percentage-based fee (configurable via FEE_PERCENTAGE env var, in basis points)
  - Minimum fee floor (configurable via MIN_FEE env var, in wei)
  - Fee = max(gasAmount * feePercentage / 10000, minFee)
  - Excess payments refunded to sender
- **Error Handling**: Custom errors for insufficient payment and transfer failures
- **Deployment**: Single contract deployment with immutable parameters (all set via env vars)

## Testing Strategy

Tests use Foundry's testing framework with:
- Unit tests for core functionality
- Fuzz testing for edge cases
- Event emission verification
- Error condition testing
- Gas optimization validation

## Network Support

Configured for multiple networks:
- **Base Sepolia** (testnet): Chain ID 84532, USDC at 0x036CbD53842c5426634e7929541eC2318f3dCF7e
- **Base Mainnet**: Chain ID 8453, USDC at 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913
- **Avalanche networks** and **Ethereum** networks also supported

## CI/CD

GitHub Actions workflow deploys on tags:
- `v*` tags deploy to production environment
- `test*` tags deploy to test environment
- Automatic contract verification on block explorers
- Deployment output includes contract address for UI configuration