# GitHub Actions Variables Setup

To deploy the Gas Payer Contract via GitHub Actions, you need to configure the following variables and secrets in your repository settings.

## Repository Settings Location
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Set up two environments: `production` and `test`

## Required Secrets (Sensitive Data)

### `DEPLOYMENT_WALLET_PRIVATE_KEY`
- **Type**: Secret (both environments)
- **Value**: Private key for wallet that will deploy contracts
- **Format**: `0x1234567890abcdef...` (64 hex characters)
- **Note**: This wallet only needs ETH for deployment gas costs. Runtime callers can be different wallets.

### `VERIFIER_API_KEY`
- **Type**: Secret (both environments)  
- **Value**: API key for contract verification on block explorer
- **Example**: Basescan API key for Base network
- **Note**: Get from the respective block explorer (basescan.org, etc.)

## Required Variables (Non-Sensitive Data)

### Fee Configuration
**`FEE_RECIPIENT`**
- **Type**: Variable
- **Value**: Ethereum address that will receive fees
- **Example**: `0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8`

**`FEE_PERCENTAGE_IN_BP`**
- **Type**: Variable  
- **Value**: Fee percentage in basis points
- **Examples**: 
  - `100` = 1%
  - `250` = 2.5%
  - `50` = 0.5%

**`MIN_FEE_WEI`**
- **Type**: Variable
- **Value**: Minimum fee in wei
- **Examples**:
  - `1000000000000000` = 0.001 ETH
  - `5000000000000000` = 0.005 ETH
  - `10000000000000000` = 0.01 ETH

### Network Configuration

**`NETWORK_RPC_URL`**
- **Type**: Variable
- **Production**: `https://mainnet.base.org`
- **Test**: `https://sepolia.base.org`

**`VERIFIER_URL`**
- **Type**: Variable
- **Production**: `https://api.basescan.org/api`
- **Test**: `https://api-sepolia.basescan.org/api`


## Environment-Specific Setup

### Production Environment (for `v*` tags)
Set all variables with mainnet values:
```
FEE_RECIPIENT=0x... (your mainnet address)
FEE_PERCENTAGE_IN_BP=100 (1% - adjust as needed)
MIN_FEE_WEI=1000000000000000 (0.001 ETH - adjust as needed)
NETWORK_RPC_URL=https://mainnet.base.org
VERIFIER_URL=https://api.basescan.org/api
```

### Test Environment (for `test*` tags)
Set all variables with testnet values:
```
FEE_RECIPIENT=0x... (your testnet address)
FEE_PERCENTAGE_IN_BP=100 (same as production for testing)
MIN_FEE_WEI=1000000000000000 (same as production for testing)
NETWORK_RPC_URL=https://sepolia.base.org
VERIFIER_URL=https://api-sepolia.basescan.org/api
```

## Deployment Triggers

### Production Deployment
- Push a tag starting with `v`: `git tag v1.0.0 && git push origin v1.0.0`
- Uses production environment variables

### Test Deployment  
- Push a tag starting with `test`: `git tag test-v1.0.0 && git push origin test-v1.0.0`
- Uses test environment variables

## Important Notes

**Deployment vs Runtime Usage:**
- `DEPLOYMENT_WALLET_PRIVATE_KEY` is only used once to deploy the contract
- At runtime, any wallet/address can call the contract to fund user gas
- Your backend service(s) can use different private keys than the deployment wallet
- The contract has no restrictions on who can call `fundAndRelay()`

## Setup Checklist

- [ ] Deployment wallet has ETH for gas on target network
- [ ] Block explorer API key obtained
- [ ] Fee recipient address confirmed
- [ ] Fee percentage and minimum decided
- [ ] All secrets added to GitHub (both environments)
- [ ] All variables added to GitHub (both environments)
- [ ] Test deployment with `test*` tag first
- [ ] Production deployment with `v*` tag

## Example Values for Base Sepolia Testing

```bash
# Secrets
DEPLOYMENT_WALLET_PRIVATE_KEY=0x... (your private key)
VERIFIER_API_KEY=... (from basescan.org)

# Variables
FEE_RECIPIENT=0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb8
FEE_PERCENTAGE_IN_BP=100
MIN_FEE_WEI=1000000000000000
NETWORK_RPC_URL=https://sepolia.base.org
VERIFIER_URL=https://api-sepolia.basescan.org/api
```

After deployment, the workflow will output the deployed contract address for use in your backend integration.