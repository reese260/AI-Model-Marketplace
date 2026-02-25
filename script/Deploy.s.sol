// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/ReputationNFT.sol";
import "../src/ProviderStaking.sol";
import "../src/TrainingVerification.sol";
import "../src/ModelTrainingEscrow.sol";
import "../src/JobMarketplace.sol";
import "../src/Groth16Verifier.sol";
import "../src/ZKTrainingVerifier.sol";

/**
 * @title Deploy
 * @notice Deployment script for AI Marketplace contracts (UUPS Proxy pattern)
 * @dev Deploys all contracts behind ERC1967 proxies and wires them together
 */
contract Deploy is Script {
    // Configuration parameters
    uint256 constant MIN_DATA_PROVIDER_STAKE = 0.1 ether;
    uint256 constant MIN_COMPUTE_PROVIDER_STAKE = 0.5 ether;
    uint256 constant CHALLENGE_PERIOD = 24 hours;
    uint256 constant PLATFORM_FEE_PERCENT = 1000; // 10%

    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy ReputationNFT (impl + proxy)
        console.log("\n1. Deploying ReputationNFT...");
        ReputationNFT reputationNFTImpl = new ReputationNFT();
        ERC1967Proxy reputationNFTProxy = new ERC1967Proxy(
            address(reputationNFTImpl),
            abi.encodeCall(ReputationNFT.initialize, ())
        );
        ReputationNFT reputationNFT = ReputationNFT(address(reputationNFTProxy));
        console.log("ReputationNFT Proxy:", address(reputationNFT));
        console.log("ReputationNFT Impl:", address(reputationNFTImpl));

        // 2. Deploy ProviderStaking (impl + proxy)
        console.log("\n2. Deploying ProviderStaking...");
        ProviderStaking providerStakingImpl = new ProviderStaking();
        ERC1967Proxy providerStakingProxy = new ERC1967Proxy(
            address(providerStakingImpl),
            abi.encodeCall(ProviderStaking.initialize, (MIN_DATA_PROVIDER_STAKE, MIN_COMPUTE_PROVIDER_STAKE))
        );
        ProviderStaking providerStaking = ProviderStaking(address(providerStakingProxy));
        console.log("ProviderStaking Proxy:", address(providerStaking));
        console.log("ProviderStaking Impl:", address(providerStakingImpl));

        // 3. Deploy TrainingVerification (impl + proxy)
        console.log("\n3. Deploying TrainingVerification...");
        TrainingVerification trainingVerificationImpl = new TrainingVerification();
        ERC1967Proxy trainingVerificationProxy = new ERC1967Proxy(
            address(trainingVerificationImpl),
            abi.encodeCall(TrainingVerification.initialize, (CHALLENGE_PERIOD))
        );
        TrainingVerification trainingVerification = TrainingVerification(address(trainingVerificationProxy));
        console.log("TrainingVerification Proxy:", address(trainingVerification));
        console.log("TrainingVerification Impl:", address(trainingVerificationImpl));

        // 4. Deploy ModelTrainingEscrow (impl + proxy)
        console.log("\n4. Deploying ModelTrainingEscrow...");
        ModelTrainingEscrow escrowImpl = new ModelTrainingEscrow();
        ERC1967Proxy escrowProxy = new ERC1967Proxy(
            address(escrowImpl),
            abi.encodeCall(ModelTrainingEscrow.initialize, (PLATFORM_FEE_PERCENT, deployer))
        );
        ModelTrainingEscrow escrow = ModelTrainingEscrow(address(escrowProxy));
        console.log("ModelTrainingEscrow Proxy:", address(escrow));
        console.log("ModelTrainingEscrow Impl:", address(escrowImpl));

        // 5. Deploy Groth16Verifier (no proxy - auto-generated, immutable)
        console.log("\n5. Deploying Groth16Verifier...");
        Groth16Verifier groth16Verifier = new Groth16Verifier();
        console.log("Groth16Verifier deployed at:", address(groth16Verifier));

        // 6. Deploy ZKTrainingVerifier (impl + proxy)
        console.log("\n6. Deploying ZKTrainingVerifier...");
        ZKTrainingVerifier zkVerifierImpl = new ZKTrainingVerifier();
        ERC1967Proxy zkVerifierProxy = new ERC1967Proxy(
            address(zkVerifierImpl),
            abi.encodeCall(ZKTrainingVerifier.initialize, (address(groth16Verifier)))
        );
        ZKTrainingVerifier zkVerifier = ZKTrainingVerifier(address(zkVerifierProxy));
        console.log("ZKTrainingVerifier Proxy:", address(zkVerifier));
        console.log("ZKTrainingVerifier Impl:", address(zkVerifierImpl));

        // 7. Deploy JobMarketplace (impl + proxy)
        console.log("\n7. Deploying JobMarketplace...");
        JobMarketplace marketplaceImpl = new JobMarketplace();
        ERC1967Proxy marketplaceProxy = new ERC1967Proxy(
            address(marketplaceImpl),
            abi.encodeCall(JobMarketplace.initialize, (
                address(reputationNFT),
                address(providerStaking),
                address(trainingVerification),
                address(escrow)
            ))
        );
        JobMarketplace marketplace = JobMarketplace(address(marketplaceProxy));
        console.log("JobMarketplace Proxy:", address(marketplace));
        console.log("JobMarketplace Impl:", address(marketplaceImpl));

        // 8. Configure contract permissions
        console.log("\n8. Configuring contract permissions...");

        // Allow marketplace to update reputation
        reputationNFT.setAuthorizedUpdater(address(marketplace), true);
        console.log("Authorized JobMarketplace to update reputation");

        // Allow marketplace to lock/unlock stakes
        providerStaking.setAuthorizedContract(address(marketplace), true);
        console.log("Authorized JobMarketplace to manage stakes");

        // Allow marketplace to submit verification results
        trainingVerification.setAuthorizedSubmitter(address(marketplace), true);
        console.log("Authorized JobMarketplace to submit verifications");

        // Allow marketplace to manage escrows
        escrow.setAuthorizedManager(address(marketplace), true);
        console.log("Authorized JobMarketplace to manage escrows");

        // Configure ZK verifier on TrainingVerification
        trainingVerification.setZKVerifier(address(zkVerifier));
        console.log("Configured ZK verifier on TrainingVerification");

        // Configure ReputationNFT on ProviderStaking for reputation-weighted slashing
        providerStaking.setReputationNFT(address(reputationNFT));
        console.log("Configured ReputationNFT on ProviderStaking");

        vm.stopBroadcast();

        // 9. Print deployment summary
        console.log("\n=== Deployment Summary ===");
        console.log("ReputationNFT Proxy:", address(reputationNFT));
        console.log("ProviderStaking Proxy:", address(providerStaking));
        console.log("TrainingVerification Proxy:", address(trainingVerification));
        console.log("ModelTrainingEscrow Proxy:", address(escrow));
        console.log("Groth16Verifier:", address(groth16Verifier));
        console.log("ZKTrainingVerifier Proxy:", address(zkVerifier));
        console.log("JobMarketplace Proxy:", address(marketplace));
        console.log("\n=== Configuration ===");
        console.log("Min Data Provider Stake:", MIN_DATA_PROVIDER_STAKE);
        console.log("Min Compute Provider Stake:", MIN_COMPUTE_PROVIDER_STAKE);
        console.log("Challenge Period:", CHALLENGE_PERIOD, "seconds");
        console.log("Platform Fee:", PLATFORM_FEE_PERCENT / 100, "%");

        // 10. Save deployment addresses to file
        string memory deploymentInfo = string.concat(
            "ReputationNFT_Proxy=", vm.toString(address(reputationNFT)), "\n",
            "ReputationNFT_Impl=", vm.toString(address(reputationNFTImpl)), "\n",
            "ProviderStaking_Proxy=", vm.toString(address(providerStaking)), "\n",
            "ProviderStaking_Impl=", vm.toString(address(providerStakingImpl)), "\n",
            "TrainingVerification_Proxy=", vm.toString(address(trainingVerification)), "\n",
            "TrainingVerification_Impl=", vm.toString(address(trainingVerificationImpl)), "\n",
            "ModelTrainingEscrow_Proxy=", vm.toString(address(escrow)), "\n",
            "ModelTrainingEscrow_Impl=", vm.toString(address(escrowImpl)), "\n",
            "Groth16Verifier=", vm.toString(address(groth16Verifier)), "\n",
            "ZKTrainingVerifier_Proxy=", vm.toString(address(zkVerifier)), "\n",
            "ZKTrainingVerifier_Impl=", vm.toString(address(zkVerifierImpl)), "\n",
            "JobMarketplace_Proxy=", vm.toString(address(marketplace)), "\n",
            "JobMarketplace_Impl=", vm.toString(address(marketplaceImpl)), "\n"
        );

        vm.writeFile("deployments.txt", deploymentInfo);
        console.log("\nDeployment addresses saved to deployments.txt");
    }
}
