// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/JobMarketplace.sol";
import "../src/ReputationNFT.sol";
import "../src/ProviderStaking.sol";
import "../src/TrainingVerification.sol";
import "../src/ModelTrainingEscrow.sol";

/**
 * @title Demo
 * @notice On-chain demonstration script for the AI Model Marketplace
 * @dev Runs a full end-to-end workflow on Polygon Amoy testnet
 *
 * Demonstrates:
 * 1. Provider registration & reputation NFT minting
 * 2. Staking collateral (data + compute providers)
 * 3. Job creation with escrow payment
 * 4. Provider application & selection
 * 5. Dataset upload & model training submission
 * 6. Optimistic verification with challenge period
 * 7. Job finalization with payment distribution
 * 8. Pull-payment withdrawal
 * 9. Reputation score tracking
 */
contract Demo is Script {
    // Deployed contract addresses - will be loaded from deployments.txt
    JobMarketplace public marketplace;
    ReputationNFT public reputationNFT;
    ProviderStaking public providerStaking;
    TrainingVerification public trainingVerification;
    ModelTrainingEscrow public escrow;

    function run() external {
        // Load deployer key
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        // Load contract addresses from deployments.txt
        string memory deployments = vm.readFile("deployments.txt");
        address marketplaceAddr = _parseAddress(deployments, "JobMarketplace_Proxy=");
        address reputationNFTAddr = _parseAddress(deployments, "ReputationNFT_Proxy=");
        address providerStakingAddr = _parseAddress(deployments, "ProviderStaking_Proxy=");
        address trainingVerificationAddr = _parseAddress(deployments, "TrainingVerification_Proxy=");
        address escrowAddr = _parseAddress(deployments, "ModelTrainingEscrow_Proxy=");

        marketplace = JobMarketplace(marketplaceAddr);
        reputationNFT = ReputationNFT(reputationNFTAddr);
        providerStaking = ProviderStaking(providerStakingAddr);
        trainingVerification = TrainingVerification(trainingVerificationAddr);
        escrow = ModelTrainingEscrow(escrowAddr);

        console.log("=== AI Model Marketplace Demo ===");
        console.log("Deployer/Requester:", deployer);
        console.log("Balance:", deployer.balance);

        // We use the deployer as requester, and deterministic keys for demo providers
        // In a real scenario these would be separate wallets
        uint256 dataProviderKey = uint256(keccak256("demo-data-provider"));
        uint256 computeProviderKey = uint256(keccak256("demo-compute-provider"));
        address dataProvider = vm.addr(dataProviderKey);
        address computeProvider = vm.addr(computeProviderKey);
        console.log("Data Provider:", dataProvider);
        console.log("Compute Provider:", computeProvider);

        vm.startBroadcast(deployerKey);

        // ============================================================
        // STEP 1: Register Providers & Mint Reputation NFTs
        // ============================================================
        console.log("\n--- Step 1: Register Providers ---");

        reputationNFT.registerProvider(dataProvider);
        console.log("Registered data provider - Reputation NFT minted");

        reputationNFT.registerProvider(computeProvider);
        console.log("Registered compute provider - Reputation NFT minted");

        // Check initial reputation
        ReputationNFT.ReputationData memory dataRep = reputationNFT.getProviderReputation(dataProvider);
        console.log("Data provider initial reputation:", dataRep.score);

        ReputationNFT.ReputationData memory computeRep = reputationNFT.getProviderReputation(computeProvider);
        console.log("Compute provider initial reputation:", computeRep.score);

        vm.stopBroadcast();

        // ============================================================
        // STEP 2: Stake Collateral
        // ============================================================
        console.log("\n--- Step 2: Stake Collateral ---");

        // Fund providers (deployer sends them POL)
        vm.startBroadcast(deployerKey);
        payable(dataProvider).transfer(0.2 ether);
        payable(computeProvider).transfer(0.6 ether);
        vm.stopBroadcast();

        // Data provider stakes 0.1 POL
        vm.startBroadcast(dataProviderKey);
        providerStaking.stake{value: 0.1 ether}(ProviderStaking.ProviderType.DATA);
        console.log("Data provider staked 0.1 POL");
        vm.stopBroadcast();

        // Compute provider stakes 0.5 POL
        vm.startBroadcast(computeProviderKey);
        providerStaking.stake{value: 0.5 ether}(ProviderStaking.ProviderType.COMPUTE);
        console.log("Compute provider staked 0.5 POL");
        vm.stopBroadcast();

        // ============================================================
        // STEP 3: Create Job (Requester posts AI training job)
        // ============================================================
        console.log("\n--- Step 3: Create Training Job ---");

        vm.startBroadcast(deployerKey);
        bytes32 jobId = marketplace.createJob{value: 0.01 ether}(
            "QmTrainGPT4FineTune_SentimentAnalysis_v1",  // IPFS hash of job details
            2000,   // 20% for data provider
            7000,   // 70% for compute provider (10% platform fee)
            0.1 ether,  // Required data provider stake
            0.5 ether,  // Required compute provider stake
            block.timestamp + 30 days  // Deadline
        );
        console.log("Job created with ID:");
        console.logBytes32(jobId);
        console.log("Payment: 0.01 POL escrowed");
        vm.stopBroadcast();

        // ============================================================
        // STEP 4: Providers Apply for the Job
        // ============================================================
        console.log("\n--- Step 4: Providers Apply ---");

        vm.startBroadcast(dataProviderKey);
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.DATA);
        console.log("Data provider applied for job");
        vm.stopBroadcast();

        vm.startBroadcast(computeProviderKey);
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.COMPUTE);
        console.log("Compute provider applied for job");
        vm.stopBroadcast();

        // ============================================================
        // STEP 5: Requester Assigns Providers
        // ============================================================
        console.log("\n--- Step 5: Assign Providers ---");

        vm.startBroadcast(deployerKey);
        marketplace.assignProviders(jobId, dataProvider, computeProvider);
        console.log("Providers assigned - stakes locked");
        vm.stopBroadcast();

        // Verify stakes are locked
        ProviderStaking.StakeInfo memory dataStake = providerStaking.getStakeInfo(dataProvider);
        ProviderStaking.StakeInfo memory computeStake = providerStaking.getStakeInfo(computeProvider);
        console.log("Data provider locked stake:", dataStake.lockedAmount);
        console.log("Compute provider locked stake:", computeStake.lockedAmount);

        // ============================================================
        // STEP 6: Data Provider Uploads Encrypted Dataset
        // ============================================================
        console.log("\n--- Step 6: Upload Dataset ---");

        vm.startBroadcast(dataProviderKey);
        marketplace.uploadDataset(jobId, "QmEncryptedSentimentDataset_10k_samples");
        console.log("Dataset uploaded: QmEncryptedSentimentDataset_10k_samples");
        vm.stopBroadcast();

        // ============================================================
        // STEP 7: Compute Provider Submits Trained Model
        // ============================================================
        console.log("\n--- Step 7: Submit Training Result ---");

        vm.startBroadcast(computeProviderKey);
        marketplace.submitTraining(
            jobId,
            "QmTrainedSentimentModel_accuracy_94pct",  // IPFS hash of model
            "QmTrainingMetrics_loss_0.03_f1_0.92"       // IPFS hash of metrics
        );
        console.log("Training submitted - entering 24h challenge period");
        console.log("Model: QmTrainedSentimentModel_accuracy_94pct");
        console.log("Metrics: QmTrainingMetrics_loss_0.03_f1_0.92");
        vm.stopBroadcast();

        // Check job status
        JobMarketplace.Job memory job = marketplace.getJob(jobId);
        console.log("Job status: SUBMITTED (enum value:", uint256(job.status), ")");

        console.log("\n=== Demo Complete ===");
        console.log("Job is now in SUBMITTED status awaiting verification.");
        console.log("In production, after the 24h challenge period passes,");
        console.log("anyone can call trainingVerification.verifyTraining(jobId)");
        console.log("followed by marketplace.finalizeJob(jobId) to complete the workflow.");
        console.log("\nTo finalize, run: forge script script/DemoFinalize.s.sol ...");
    }

    function _parseAddress(string memory data, string memory key) internal pure returns (address) {
        bytes memory dataBytes = bytes(data);
        bytes memory keyBytes = bytes(key);

        for (uint256 i = 0; i < dataBytes.length - keyBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < keyBytes.length; j++) {
                if (dataBytes[i + j] != keyBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                // Extract 42 chars (0x + 40 hex)
                bytes memory addrStr = new bytes(42);
                for (uint256 k = 0; k < 42; k++) {
                    addrStr[k] = dataBytes[i + keyBytes.length + k];
                }
                return _hexToAddress(string(addrStr));
            }
        }
        revert(string.concat("Key not found: ", key));
    }

    function _hexToAddress(string memory s) internal pure returns (address) {
        bytes memory ss = bytes(s);
        require(ss.length == 42, "Invalid address length");
        uint160 result = 0;
        for (uint256 i = 2; i < 42; i++) {
            result *= 16;
            uint8 b = uint8(ss[i]);
            if (b >= 48 && b <= 57) {
                result += uint160(b - 48);
            } else if (b >= 65 && b <= 70) {
                result += uint160(b - 55);
            } else if (b >= 97 && b <= 102) {
                result += uint160(b - 87);
            }
        }
        return address(result);
    }
}
