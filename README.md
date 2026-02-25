# AI Model Training Marketplace

A decentralized blockchain platform that connects three key parties in the AI ecosystem: data providers, model requesters, and compute providers with GPU resources. Smart contracts coordinate the entire training process from job posting to payment distribution, ensuring trust and transparency without central authority.

## Overview

This platform creates a trustless marketplace for AI model training by:
- Enabling model requesters to post training jobs with escrowed payments
- Allowing data providers to securely share encrypted datasets while earning rewards
- Connecting compute providers who contribute GPU resources for training
- Using smart contracts to automate the entire workflow
- Building on-chain reputation for quality assurance
- Operating fully decentralized on Polygon for low gas fees

## Key Features

### Escrow-Based Payments
- Payments locked in smart contracts until training completion
- Automatic distribution to providers after verification
- Refund mechanism for failed or cancelled jobs
- Platform fee collection

### Provider Staking System
- Data and compute providers stake collateral
- Stakes locked during active jobs
- Slashing mechanism for misconduct
- Minimum stake requirements for quality assurance

### Optimistic Verification
- Training results submitted to blockchain
- 24-hour challenge period for disputes
- Automatic verification if no challenges
- Dispute resolution by governance
- Future upgrade path to ZK proofs

### On-Chain Reputation NFTs
- Non-transferable NFTs tracking provider history
- Reputation scores (0-1000)
- Job completion metrics
- Slash history tracking

### Privacy-Preserving Data Sharing
- Encrypted datasets stored on IPFS
- Dataset hashes recorded on-chain
- Off-chain training computation
- Results verified through challenge mechanism

## Smart Contracts

### 1. ReputationNFT.sol
Manages on-chain reputation for providers through non-transferable NFTs.

**Key Functions:**
- `registerProvider(address)` - Mint reputation NFT for new provider
- `updateReputation(address, bool, uint256)` - Update reputation after job
- `getProviderReputation(address)` - Retrieve reputation data

**Features:**
- Non-transferable reputation tokens
- Score range: 0-1000 (starts at 500)
- Tracks completed jobs, failures, and slashed stakes

### 2. ProviderStaking.sol
Handles collateral staking for data and compute providers.

**Key Functions:**
- `stake(ProviderType)` - Stake collateral to become a provider
- `unstake(uint256)` - Withdraw available stake
- `lockStake(address, uint256, bytes32)` - Lock stake for active job
- `unlockStake(address, uint256, bytes32)` - Unlock after completion
- `slashStake(address, uint256, bytes32, address)` - Slash for misconduct

**Features:**
- Separate minimums for data/compute providers
- Locked vs available stake tracking
- Authorized contract management

### 3. TrainingVerification.sol
Implements optimistic verification for training results.

**Key Functions:**
- `submitTrainingResult(bytes32, address, string, string)` - Submit training
- `challengeTraining(bytes32, string)` - Challenge submitted training
- `verifyTraining(bytes32)` - Verify after challenge period
- `resolveDispute(bytes32, bool)` - Resolve disputed training

**Features:**
- 24-hour challenge period
- IPFS hash storage for models and metrics
- Dispute resolution workflow
- Challenge tracking

### 4. ModelTrainingEscrow.sol
Manages payment escrow for training jobs.

**Key Functions:**
- `createEscrow(bytes32, address, address, address, uint256, uint256)` - Create escrow
- `completeEscrow(bytes32)` - Mark as ready for release
- `releaseEscrow(bytes32)` - Distribute payments to providers
- `refundEscrow(bytes32)` - Refund to requester

**Features:**
- Configurable payment splits
- Platform fee collection
- Secure fund holding
- Automatic distribution

### 5. JobMarketplace.sol
Main orchestration contract coordinating the entire workflow.

**Key Functions:**
- `createJob(...)` - Post new training job
- `applyForJob(bytes32, ProviderType)` - Apply as provider
- `assignProviders(bytes32, address, address)` - Select providers
- `uploadDataset(bytes32, string)` - Upload encrypted data
- `submitTraining(bytes32, string, string)` - Submit trained model
- `finalizeJob(bytes32)` - Complete and distribute payments

**Features:**
- Complete job lifecycle management
- Provider application system
- Stake locking coordination
- Multi-contract orchestration

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      JobMarketplace                          │
│                  (Main Orchestrator)                         │
└────┬──────────────┬──────────────┬──────────────┬───────────┘
     │              │              │              │
     ▼              ▼              ▼              ▼
┌─────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐
│Reputation│  │Provider  │  │Training  │  │Model Training│
│   NFT    │  │ Staking  │  │Verification│  │   Escrow     │
└─────────┘  └──────────┘  └──────────┘  └──────────────┘
```

## Workflow

### 1. Provider Registration
```solidity
// Register and stake
reputationNFT.registerProvider(provider);
providerStaking.stake{value: amount}(ProviderType.DATA);
```

### 2. Job Creation
```solidity
marketplace.createJob{value: payment}(
    "QmJobDetailsIPFS",
    dataShare,      // e.g., 2000 = 20%
    computeShare,   // e.g., 7000 = 70%
    dataStake,
    computeStake,
    deadline
);
```

### 3. Provider Application
```solidity
marketplace.applyForJob(jobId, ProviderType.DATA);
marketplace.applyForJob(jobId, ProviderType.COMPUTE);
```

### 4. Provider Assignment
```solidity
marketplace.assignProviders(jobId, dataProvider, computeProvider);
// Stakes automatically locked, escrow created
```

### 5. Training Execution
```solidity
// Data provider uploads encrypted dataset
marketplace.uploadDataset(jobId, "QmDatasetIPFS");

// Compute provider trains model (off-chain)
// Then submits results
marketplace.submitTraining(jobId, "QmModelIPFS", "QmMetricsIPFS");
```

### 6. Verification & Payment
```solidity
// Wait 24 hours for challenges
// Anyone can verify after challenge period
trainingVerification.verifyTraining(jobId);

// Finalize job and distribute payments
marketplace.finalizeJob(jobId);
```

## Technology Stack

- **Smart Contracts**: Solidity 0.8.24
- **Development Framework**: Foundry
- **Testing**: Forge (Foundry's testing framework)
- **Blockchain**: Polygon (low gas fees)
- **Storage**: IPFS (datasets, models, metrics)
- **Dependencies**: OpenZeppelin Contracts

## Installation

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd AI-Model-Marketplace

# Install dependencies
forge install

# Compile contracts
forge build

# Run tests
forge test

# Run tests with verbose output
forge test -vvv
```

## Testing

The project includes comprehensive tests covering:
- Full job workflow from creation to completion
- Provider registration and staking
- Insufficient stake scenarios
- Job cancellation
- Training challenges and disputes
- Payment distribution

Run all tests:
```bash
forge test
```

Run with gas reporting:
```bash
forge test --gas-report
```

Run specific test:
```bash
forge test --match-test testFullJobWorkflow -vvv
```

## Deployment

### Local Deployment (Anvil)
```bash
# Start local node
anvil

# Deploy contracts
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Polygon Mumbai Testnet
```bash
# 1. Set up environment variables
cp .env.example .env
# Edit .env with your private key and RPC URL

# 2. Deploy
forge script script/Deploy.s.sol \
    --rpc-url $POLYGON_MUMBAI_RPC_URL \
    --broadcast \
    --verify

# Deployment addresses saved to deployments.txt
```

### Polygon Mainnet
```bash
forge script script/Deploy.s.sol \
    --rpc-url $POLYGON_MAINNET_RPC_URL \
    --broadcast \
    --verify \
    --slow
```

## Configuration

Adjust these parameters in `script/Deploy.s.sol`:

```solidity
uint256 constant MIN_DATA_PROVIDER_STAKE = 0.1 ether;
uint256 constant MIN_COMPUTE_PROVIDER_STAKE = 0.5 ether;
uint256 constant CHALLENGE_PERIOD = 24 hours;
uint256 constant PLATFORM_FEE_PERCENT = 1000; // 10%
```

## Security Considerations

### Implemented Protections
- ReentrancyGuard on all payment functions
- Access control with Ownable pattern
- Stake locking during active jobs
- Challenge period for training verification
- Non-transferable reputation NFTs

### Future Enhancements
- Multi-signature governance for dispute resolution
- ZK-proof based verification
- Insurance fund for slashed stakes
- Decentralized governance (DAO)
- Rate limiting on job creation

## Future Roadmap

### Phase 1 (Current)
- ✅ Core smart contracts
- ✅ Optimistic verification
- ✅ Basic reputation system
- ✅ Comprehensive tests

### Phase 2
- React frontend (Web3)
- IPFS integration for file storage
- Provider dashboard
- Job marketplace UI

### Phase 3
- Off-chain training infrastructure
- PyTorch/TensorFlow integration
- Encrypted data handling
- Training metrics reporting

### Phase 4
- ZK-proof verification
- Advanced reputation algorithms
- Cross-chain support
- DAO governance

## Gas Optimization

The contracts use several gas optimization techniques:
- Efficient storage packing
- Minimal external calls
- Batch operations where possible
- Events for off-chain indexing

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Portfolio Highlights

This project demonstrates:
- **Complex Multi-Party Coordination**: Three different actor types with different incentives
- **Blockchain + AI Integration**: Novel use case combining two cutting-edge technologies
- **Cryptographic Verification**: Optimistic verification with challenge mechanism
- **DeFi Mechanics**: Staking, slashing, escrow, and automated payments
- **Production-Ready Code**: Comprehensive tests, security measures, deployment scripts
- **Real Market Need**: Addresses actual inefficiency in AI training market
- **Legal Safety**: No gambling, securities, or regulatory concerns
- **Scalability**: Built on Polygon for low costs and high throughput

## Support & Questions

For questions or support:
- Open an issue on GitHub
- Review the test files for usage examples
- Check the inline documentation in smart contracts

## Disclaimer

This is experimental software. Use at your own risk. Always audit smart contracts before deploying to mainnet with real funds.
