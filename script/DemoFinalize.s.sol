// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/JobMarketplace.sol";
import "../src/ReputationNFT.sol";
import "../src/ProviderStaking.sol";
import "../src/TrainingVerification.sol";
import "../src/ModelTrainingEscrow.sol";

/**
 * @title DemoFinalize
 * @notice Finalizes a demo job after the challenge period has elapsed
 * @dev Run this after the 60-second challenge period from Demo.s.sol
 *
 * Demonstrates:
 * - Optimistic verification completion
 * - Job finalization with payment distribution
 * - Pull-payment withdrawals
 * - Reputation score updates
 * - Stake unlocking
 */
contract DemoFinalize is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        // Load contract addresses
        string memory deployments = vm.readFile("deployments.txt");
        address marketplaceAddr = _parseAddress(deployments, "JobMarketplace_Proxy=");
        address reputationNFTAddr = _parseAddress(deployments, "ReputationNFT_Proxy=");
        address providerStakingAddr = _parseAddress(deployments, "ProviderStaking_Proxy=");
        address trainingVerificationAddr = _parseAddress(deployments, "TrainingVerification_Proxy=");
        address escrowAddr = _parseAddress(deployments, "ModelTrainingEscrow_Proxy=");

        JobMarketplace marketplace = JobMarketplace(marketplaceAddr);
        ReputationNFT reputationNFT = ReputationNFT(reputationNFTAddr);
        ProviderStaking providerStaking = ProviderStaking(providerStakingAddr);
        TrainingVerification trainingVerification = TrainingVerification(trainingVerificationAddr);
        ModelTrainingEscrow escrow = ModelTrainingEscrow(escrowAddr);

        uint256 dataProviderKey = uint256(keccak256("demo-data-provider"));
        uint256 computeProviderKey = uint256(keccak256("demo-compute-provider"));
        address dataProvider = vm.addr(dataProviderKey);
        address computeProvider = vm.addr(computeProviderKey);

        // Reconstruct the job ID (same params as Demo.s.sol)
        // We need to read it from the job counter or use events
        // For demo, we know it's the first job so counter was 0
        bytes32 jobId = keccak256(abi.encodePacked(marketplaceAddr, uint256(0)));

        console.log("=== Demo Finalization ===");
        console.log("Job ID:");
        console.logBytes32(jobId);

        // Check job status
        JobMarketplace.Job memory job = marketplace.getJob(jobId);
        console.log("Current job status (enum):", uint256(job.status));

        if (job.status != JobMarketplace.JobStatus.SUBMITTED) {
            console.log("ERROR: Job is not in SUBMITTED status. Cannot finalize.");
            return;
        }

        // Check verification status
        TrainingVerification.VerificationStatus vStatus = trainingVerification.getVerificationStatus(jobId);
        console.log("Verification status (enum):", uint256(vStatus));

        // ============================================================
        // STEP 8: Verify Training (after challenge period)
        // ============================================================
        console.log("\n--- Step 8: Verify Training ---");

        vm.startBroadcast(deployerKey);
        trainingVerification.verifyTraining(jobId);
        console.log("Training verified - challenge period passed with no disputes");
        vm.stopBroadcast();

        // ============================================================
        // STEP 9: Finalize Job
        // ============================================================
        console.log("\n--- Step 9: Finalize Job ---");

        uint256 dataBalBefore = dataProvider.balance;
        uint256 computeBalBefore = computeProvider.balance;
        uint256 deployerBalBefore = deployer.balance;

        vm.startBroadcast(deployerKey);
        marketplace.finalizeJob(jobId);
        console.log("Job finalized - payments released to escrow");
        vm.stopBroadcast();

        // ============================================================
        // STEP 10: Withdraw Payments (Pull-Payment Pattern)
        // ============================================================
        console.log("\n--- Step 10: Withdraw Payments ---");

        // Data provider withdraws
        uint256 dataPending = escrow.pendingWithdrawals(dataProvider);
        console.log("Data provider pending withdrawal:", dataPending);
        if (dataPending > 0) {
            vm.startBroadcast(dataProviderKey);
            escrow.withdraw();
            vm.stopBroadcast();
            console.log("Data provider withdrew:", dataProvider.balance - dataBalBefore);
        }

        // Compute provider withdraws
        uint256 computePending = escrow.pendingWithdrawals(computeProvider);
        console.log("Compute provider pending withdrawal:", computePending);
        if (computePending > 0) {
            vm.startBroadcast(computeProviderKey);
            escrow.withdraw();
            vm.stopBroadcast();
            console.log("Compute provider withdrew:", computeProvider.balance - computeBalBefore);
        }

        // Platform fee (deployer is fee recipient)
        uint256 feePending = escrow.pendingWithdrawals(deployer);
        console.log("Platform fee pending:", feePending);
        if (feePending > 0) {
            vm.startBroadcast(deployerKey);
            escrow.withdraw();
            vm.stopBroadcast();
            console.log("Platform fee collected:", deployer.balance - deployerBalBefore);
        }

        // ============================================================
        // STEP 11: Check Final State
        // ============================================================
        console.log("\n--- Final State ---");

        // Job status
        job = marketplace.getJob(jobId);
        console.log("Job status: COMPLETED (enum:", uint256(job.status), ")");

        // Reputation scores
        ReputationNFT.ReputationData memory dataRep = reputationNFT.getProviderReputation(dataProvider);
        console.log("Data provider reputation:", dataRep.score);
        console.log("Data provider jobs completed:", dataRep.totalJobsCompleted);

        ReputationNFT.ReputationData memory computeRep = reputationNFT.getProviderReputation(computeProvider);
        console.log("Compute provider reputation:", computeRep.score);
        console.log("Compute provider jobs completed:", computeRep.totalJobsCompleted);

        // Stakes unlocked
        ProviderStaking.StakeInfo memory dataStake = providerStaking.getStakeInfo(dataProvider);
        ProviderStaking.StakeInfo memory computeStake = providerStaking.getStakeInfo(computeProvider);
        console.log("Data provider locked stake:", dataStake.lockedAmount, "(should be 0)");
        console.log("Compute provider locked stake:", computeStake.lockedAmount, "(should be 0)");

        console.log("\n=== Demo Complete ===");
        console.log("Full marketplace workflow demonstrated on Polygon Amoy!");
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
            if (b >= 48 && b <= 57) result += uint160(b - 48);
            else if (b >= 65 && b <= 70) result += uint160(b - 55);
            else if (b >= 97 && b <= 102) result += uint160(b - 87);
        }
        return address(result);
    }
}
