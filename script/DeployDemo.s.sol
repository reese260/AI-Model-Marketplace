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
import "../test/mocks/MockZKVerifier.sol";

/**
 * @title DeployDemo
 * @notice Demo deployment with shortened challenge period (60s) for testnet demonstrations
 * @dev Uses MockZKVerifier to allow ZK proof path demonstration without real proofs
 */
contract DeployDemo is Script {
    uint256 constant MIN_DATA_PROVIDER_STAKE = 0.1 ether;
    uint256 constant MIN_COMPUTE_PROVIDER_STAKE = 0.5 ether;
    uint256 constant CHALLENGE_PERIOD = 60; // 60 seconds for demo (vs 24h in production)
    uint256 constant PLATFORM_FEE_PERCENT = 1000; // 10%

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Demo Deployment (Polygon Amoy) ===");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);
        console.log("Challenge period: 60 seconds (demo mode)");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy ReputationNFT
        ReputationNFT reputationNFTImpl = new ReputationNFT();
        ReputationNFT reputationNFT = ReputationNFT(address(new ERC1967Proxy(
            address(reputationNFTImpl),
            abi.encodeCall(ReputationNFT.initialize, ())
        )));
        console.log("ReputationNFT Proxy:", address(reputationNFT));

        // 2. Deploy ProviderStaking
        ProviderStaking providerStakingImpl = new ProviderStaking();
        ProviderStaking providerStaking = ProviderStaking(address(new ERC1967Proxy(
            address(providerStakingImpl),
            abi.encodeCall(ProviderStaking.initialize, (MIN_DATA_PROVIDER_STAKE, MIN_COMPUTE_PROVIDER_STAKE))
        )));
        console.log("ProviderStaking Proxy:", address(providerStaking));

        // 3. Deploy TrainingVerification (60s challenge period for demo)
        TrainingVerification trainingVerificationImpl = new TrainingVerification();
        TrainingVerification trainingVerification = TrainingVerification(address(new ERC1967Proxy(
            address(trainingVerificationImpl),
            abi.encodeCall(TrainingVerification.initialize, (CHALLENGE_PERIOD))
        )));
        console.log("TrainingVerification Proxy:", address(trainingVerification));

        // 4. Deploy ModelTrainingEscrow
        ModelTrainingEscrow escrowImpl = new ModelTrainingEscrow();
        ModelTrainingEscrow escrow = ModelTrainingEscrow(address(new ERC1967Proxy(
            address(escrowImpl),
            abi.encodeCall(ModelTrainingEscrow.initialize, (PLATFORM_FEE_PERCENT, deployer))
        )));
        console.log("ModelTrainingEscrow Proxy:", address(escrow));

        // 5. Deploy MockZKVerifier (accepts any proof for demo)
        MockZKVerifier mockZKVerifier = new MockZKVerifier();
        console.log("MockZKVerifier:", address(mockZKVerifier));

        // 6. Deploy real ZK stack for reference
        Groth16Verifier groth16Verifier = new Groth16Verifier();
        ZKTrainingVerifier zkVerifierImpl = new ZKTrainingVerifier();
        ZKTrainingVerifier zkVerifier = ZKTrainingVerifier(address(new ERC1967Proxy(
            address(zkVerifierImpl),
            abi.encodeCall(ZKTrainingVerifier.initialize, (address(groth16Verifier)))
        )));
        console.log("ZKTrainingVerifier Proxy:", address(zkVerifier));

        // 7. Deploy JobMarketplace
        JobMarketplace marketplaceImpl = new JobMarketplace();
        JobMarketplace marketplace = JobMarketplace(address(new ERC1967Proxy(
            address(marketplaceImpl),
            abi.encodeCall(JobMarketplace.initialize, (
                address(reputationNFT),
                address(providerStaking),
                address(trainingVerification),
                address(escrow)
            ))
        )));
        console.log("JobMarketplace Proxy:", address(marketplace));

        // 8. Configure permissions
        reputationNFT.setAuthorizedUpdater(address(marketplace), true);
        reputationNFT.setAuthorizedUpdater(deployer, true); // Allow deployer to register demo providers
        providerStaking.setAuthorizedContract(address(marketplace), true);
        trainingVerification.setAuthorizedSubmitter(address(marketplace), true);
        escrow.setAuthorizedManager(address(marketplace), true);

        // Use MockZKVerifier for demo (accepts any proof)
        trainingVerification.setZKVerifier(address(mockZKVerifier));
        providerStaking.setReputationNFT(address(reputationNFT));

        console.log("\nPermissions configured");

        vm.stopBroadcast();

        // Save deployment addresses
        string memory deploymentInfo = string.concat(
            "ReputationNFT_Proxy=", vm.toString(address(reputationNFT)), "\n",
            "ReputationNFT_Impl=", vm.toString(address(reputationNFTImpl)), "\n",
            "ProviderStaking_Proxy=", vm.toString(address(providerStaking)), "\n",
            "ProviderStaking_Impl=", vm.toString(address(providerStakingImpl)), "\n",
            "TrainingVerification_Proxy=", vm.toString(address(trainingVerification)), "\n",
            "TrainingVerification_Impl=", vm.toString(address(trainingVerificationImpl)), "\n",
            "ModelTrainingEscrow_Proxy=", vm.toString(address(escrow)), "\n",
            "ModelTrainingEscrow_Impl=", vm.toString(address(escrowImpl)), "\n",
            "MockZKVerifier=", vm.toString(address(mockZKVerifier)), "\n",
            "Groth16Verifier=", vm.toString(address(groth16Verifier)), "\n",
            "ZKTrainingVerifier_Proxy=", vm.toString(address(zkVerifier)), "\n",
            "ZKTrainingVerifier_Impl=", vm.toString(address(zkVerifierImpl)), "\n",
            "JobMarketplace_Proxy=", vm.toString(address(marketplace)), "\n",
            "JobMarketplace_Impl=", vm.toString(address(marketplaceImpl)), "\n"
        );

        vm.writeFile("deployments.txt", deploymentInfo);
        console.log("\nDeployment addresses saved to deployments.txt");

        console.log("\n=== Deployment Summary ===");
        console.log("Challenge Period: 60 seconds (demo)");
        console.log("Min Data Stake: 0.1 POL");
        console.log("Min Compute Stake: 0.5 POL");
        console.log("Platform Fee: 10%");
        console.log("ZK Verifier: MockZKVerifier (demo - accepts any proof)");
        console.log("\nNext: Run 'forge script script/Demo.s.sol' to demo the workflow");
    }
}
