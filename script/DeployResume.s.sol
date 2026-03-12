// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/ReputationNFT.sol";
import "../src/ProviderStaking.sol";
import "../src/TrainingVerification.sol";
import "../src/ModelTrainingEscrow.sol";
import "../src/JobMarketplace.sol";

/**
 * @title DeployResume
 * @notice Resumes partial deployment - deploys JobMarketplace and configures all permissions
 * @dev Uses already-deployed contracts from the interrupted DeployDemo run
 */
contract DeployResume is Script {
    // Already deployed proxies
    address constant REPUTATION_NFT = 0xAEd7fCD03baFCe90520b6C83F0fC8Dc736AebdE2;
    address constant PROVIDER_STAKING = 0xdcf924a393370911BEe05e5285229f9e444CeE04;
    address constant TRAINING_VERIFICATION = 0x1b07C797eC243A04A1504568081648C3Af0e5e70;
    address constant MODEL_TRAINING_ESCROW = 0x50a5cEb55D5558E732bb5F80a948CD7452ae7A51;
    address constant MOCK_ZK_VERIFIER = 0xa610E3Ceb47DdeaD4115b0559968F18BF17b7e60;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Resuming Deployment ===");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy JobMarketplace (impl + proxy)
        console.log("\nDeploying JobMarketplace...");
        JobMarketplace marketplaceImpl = new JobMarketplace();
        ERC1967Proxy marketplaceProxy = new ERC1967Proxy(
            address(marketplaceImpl),
            abi.encodeCall(JobMarketplace.initialize, (
                REPUTATION_NFT,
                PROVIDER_STAKING,
                TRAINING_VERIFICATION,
                MODEL_TRAINING_ESCROW
            ))
        );
        JobMarketplace marketplace = JobMarketplace(address(marketplaceProxy));
        console.log("JobMarketplace Proxy:", address(marketplace));
        console.log("JobMarketplace Impl:", address(marketplaceImpl));

        // Configure all permissions
        console.log("\nConfiguring permissions...");

        ReputationNFT(REPUTATION_NFT).setAuthorizedUpdater(address(marketplace), true);
        ReputationNFT(REPUTATION_NFT).setAuthorizedUpdater(deployer, true);
        console.log("Authorized marketplace + deployer on ReputationNFT");

        ProviderStaking(PROVIDER_STAKING).setAuthorizedContract(address(marketplace), true);
        console.log("Authorized marketplace on ProviderStaking");

        TrainingVerification(TRAINING_VERIFICATION).setAuthorizedSubmitter(address(marketplace), true);
        console.log("Authorized marketplace on TrainingVerification");

        ModelTrainingEscrow(MODEL_TRAINING_ESCROW).setAuthorizedManager(address(marketplace), true);
        console.log("Authorized marketplace on ModelTrainingEscrow");

        TrainingVerification(TRAINING_VERIFICATION).setZKVerifier(MOCK_ZK_VERIFIER);
        console.log("Set MockZKVerifier on TrainingVerification");

        ProviderStaking(PROVIDER_STAKING).setReputationNFT(REPUTATION_NFT);
        console.log("Set ReputationNFT on ProviderStaking");

        vm.stopBroadcast();

        // Save updated deployment addresses
        string memory deploymentInfo = string.concat(
            "ReputationNFT_Proxy=", vm.toString(REPUTATION_NFT), "\n",
            "ProviderStaking_Proxy=", vm.toString(PROVIDER_STAKING), "\n",
            "TrainingVerification_Proxy=", vm.toString(TRAINING_VERIFICATION), "\n",
            "ModelTrainingEscrow_Proxy=", vm.toString(MODEL_TRAINING_ESCROW), "\n",
            "MockZKVerifier=", vm.toString(MOCK_ZK_VERIFIER), "\n",
            "JobMarketplace_Proxy=", vm.toString(address(marketplace)), "\n",
            "JobMarketplace_Impl=", vm.toString(address(marketplaceImpl)), "\n"
        );
        vm.writeFile("deployments.txt", deploymentInfo);
        console.log("\nDeployment addresses saved to deployments.txt");

        console.log("\n=== Deployment Complete ===");
        console.log("All contracts deployed and configured on Polygon Amoy");
        console.log("Next: forge script script/Demo.s.sol --rpc-url $POLYGON_AMOY_RPC_URL --broadcast --slow --chain-id 80002");
    }
}
