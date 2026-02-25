// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/JobMarketplace.sol";
import "../src/ReputationNFT.sol";
import "../src/ProviderStaking.sol";
import "../src/TrainingVerification.sol";
import "../src/ModelTrainingEscrow.sol";

contract JobMarketplaceTest is Test {
    JobMarketplace public marketplace;
    ReputationNFT public reputationNFT;
    ProviderStaking public providerStaking;
    TrainingVerification public trainingVerification;
    ModelTrainingEscrow public escrow;

    address public owner;
    address public requester;
    address public dataProvider;
    address public computeProvider;
    address public feeRecipient;

    uint256 constant MIN_DATA_STAKE = 0.1 ether;
    uint256 constant MIN_COMPUTE_STAKE = 0.5 ether;
    uint256 constant CHALLENGE_PERIOD = 24 hours;
    uint256 constant PLATFORM_FEE = 1000; // 10%

    function setUp() public {
        owner = address(this);
        requester = makeAddr("requester");
        dataProvider = makeAddr("dataProvider");
        computeProvider = makeAddr("computeProvider");
        feeRecipient = makeAddr("feeRecipient");

        // Deploy contracts via proxy
        reputationNFT = ReputationNFT(address(new ERC1967Proxy(
            address(new ReputationNFT()),
            abi.encodeCall(ReputationNFT.initialize, ())
        )));
        providerStaking = ProviderStaking(address(new ERC1967Proxy(
            address(new ProviderStaking()),
            abi.encodeCall(ProviderStaking.initialize, (MIN_DATA_STAKE, MIN_COMPUTE_STAKE))
        )));
        trainingVerification = TrainingVerification(address(new ERC1967Proxy(
            address(new TrainingVerification()),
            abi.encodeCall(TrainingVerification.initialize, (CHALLENGE_PERIOD))
        )));
        escrow = ModelTrainingEscrow(address(new ERC1967Proxy(
            address(new ModelTrainingEscrow()),
            abi.encodeCall(ModelTrainingEscrow.initialize, (PLATFORM_FEE, feeRecipient))
        )));
        marketplace = JobMarketplace(address(new ERC1967Proxy(
            address(new JobMarketplace()),
            abi.encodeCall(JobMarketplace.initialize, (
                address(reputationNFT),
                address(providerStaking),
                address(trainingVerification),
                address(escrow)
            ))
        )));

        // Configure permissions
        reputationNFT.setAuthorizedUpdater(address(marketplace), true);
        providerStaking.setAuthorizedContract(address(marketplace), true);
        trainingVerification.setAuthorizedSubmitter(address(marketplace), true);
        escrow.setAuthorizedManager(address(marketplace), true);

        // Fund test accounts
        vm.deal(requester, 100 ether);
        vm.deal(dataProvider, 10 ether);
        vm.deal(computeProvider, 10 ether);
    }

    function testCreateJob() public {
        vm.startPrank(requester);

        uint256 paymentAmount = 1 ether;
        bytes32 jobId = marketplace.createJob{value: paymentAmount}(
            "QmTestJobDetails",
            2000, // 20% for data provider
            7000, // 70% for compute provider
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days
        );

        JobMarketplace.Job memory job = marketplace.getJob(jobId);

        assertEq(job.requester, requester);
        assertEq(job.paymentAmount, paymentAmount);
        assertEq(job.jobDetailsIPFS, "QmTestJobDetails");
        assertTrue(job.status == JobMarketplace.JobStatus.OPEN);

        vm.stopPrank();
    }

    function testProviderRegistrationAndStaking() public {
        // Register and stake as data provider
        vm.startPrank(dataProvider);
        reputationNFT.registerProvider(dataProvider);
        providerStaking.stake{value: MIN_DATA_STAKE}(ProviderStaking.ProviderType.DATA);

        assertTrue(reputationNFT.isProviderRegistered(dataProvider));
        ProviderStaking.StakeInfo memory stakeInfo = providerStaking.getStakeInfo(dataProvider);
        assertEq(stakeInfo.amount, MIN_DATA_STAKE);
        assertTrue(stakeInfo.isActive);
        vm.stopPrank();

        // Register and stake as compute provider
        vm.startPrank(computeProvider);
        reputationNFT.registerProvider(computeProvider);
        providerStaking.stake{value: MIN_COMPUTE_STAKE}(ProviderStaking.ProviderType.COMPUTE);

        assertTrue(reputationNFT.isProviderRegistered(computeProvider));
        stakeInfo = providerStaking.getStakeInfo(computeProvider);
        assertEq(stakeInfo.amount, MIN_COMPUTE_STAKE);
        vm.stopPrank();
    }

    function testFullJobWorkflow() public {
        // 1. Register providers
        vm.prank(dataProvider);
        reputationNFT.registerProvider(dataProvider);

        vm.prank(computeProvider);
        reputationNFT.registerProvider(computeProvider);

        // 2. Stake
        vm.prank(dataProvider);
        providerStaking.stake{value: MIN_DATA_STAKE}(ProviderStaking.ProviderType.DATA);

        vm.prank(computeProvider);
        providerStaking.stake{value: MIN_COMPUTE_STAKE}(ProviderStaking.ProviderType.COMPUTE);

        // 3. Create job
        vm.startPrank(requester);
        bytes32 jobId = marketplace.createJob{value: 1 ether}(
            "QmTestJobDetails",
            2000, // 20% for data
            7000, // 70% for compute
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days
        );
        vm.stopPrank();

        // 4. Providers apply
        vm.prank(dataProvider);
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.DATA);

        vm.prank(computeProvider);
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.COMPUTE);

        // 5. Assign providers
        vm.prank(requester);
        marketplace.assignProviders(jobId, dataProvider, computeProvider);

        JobMarketplace.Job memory job = marketplace.getJob(jobId);
        assertTrue(job.status == JobMarketplace.JobStatus.IN_PROGRESS);
        assertEq(job.dataProvider, dataProvider);
        assertEq(job.computeProvider, computeProvider);

        // 6. Upload dataset
        vm.prank(dataProvider);
        marketplace.uploadDataset(jobId, "QmEncryptedDataset");

        // 7. Submit training
        vm.prank(computeProvider);
        marketplace.submitTraining(jobId, "QmTrainedModel", "QmMetrics");

        job = marketplace.getJob(jobId);
        assertTrue(job.status == JobMarketplace.JobStatus.SUBMITTED);

        // 8. Wait for challenge period and verify
        vm.warp(block.timestamp + CHALLENGE_PERIOD + 1);
        trainingVerification.verifyTraining(jobId);

        // 9. Finalize job
        uint256 dataProviderBalanceBefore = dataProvider.balance;
        uint256 computeProviderBalanceBefore = computeProvider.balance;
        uint256 feeRecipientBalanceBefore = feeRecipient.balance;

        marketplace.finalizeJob(jobId);

        // Check balances
        uint256 expectedDataPayment = (1 ether * 2000) / 10000; // 0.2 ETH
        uint256 expectedComputePayment = (1 ether * 7000) / 10000; // 0.7 ETH
        uint256 expectedFee = (1 ether * 1000) / 10000; // 0.1 ETH

        assertEq(dataProvider.balance, dataProviderBalanceBefore + expectedDataPayment);
        assertEq(computeProvider.balance, computeProviderBalanceBefore + expectedComputePayment);
        assertEq(feeRecipient.balance, feeRecipientBalanceBefore + expectedFee);

        // Check reputation was updated
        ReputationNFT.ReputationData memory dataRep = reputationNFT.getProviderReputation(dataProvider);
        assertEq(dataRep.totalJobsCompleted, 1);

        ReputationNFT.ReputationData memory computeRep = reputationNFT.getProviderReputation(computeProvider);
        assertEq(computeRep.totalJobsCompleted, 1);

        // Check job status
        job = marketplace.getJob(jobId);
        assertTrue(job.status == JobMarketplace.JobStatus.COMPLETED);
    }

    function testCannotApplyWithoutRegistration() public {
        vm.startPrank(requester);
        bytes32 jobId = marketplace.createJob{value: 1 ether}(
            "QmTestJobDetails",
            2000,
            7000,
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days
        );
        vm.stopPrank();

        vm.prank(dataProvider);
        vm.expectRevert("Provider not registered");
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.DATA);
    }

    function testCannotApplyWithoutSufficientStake() public {
        vm.prank(dataProvider);
        reputationNFT.registerProvider(dataProvider);

        // Stake minimum amount (0.1 ETH)
        vm.prank(dataProvider);
        providerStaking.stake{value: MIN_DATA_STAKE}(ProviderStaking.ProviderType.DATA);

        // Create job requiring MORE stake than provider has (0.5 ETH)
        vm.startPrank(requester);
        bytes32 jobId = marketplace.createJob{value: 1 ether}(
            "QmTestJobDetails",
            2000,
            7000,
            0.5 ether, // Require more stake than provider has
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days
        );
        vm.stopPrank();

        vm.prank(dataProvider);
        vm.expectRevert("Insufficient stake");
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.DATA);
    }

    function testCancelJob() public {
        vm.startPrank(requester);
        uint256 balanceBefore = requester.balance;

        bytes32 jobId = marketplace.createJob{value: 1 ether}(
            "QmTestJobDetails",
            2000,
            7000,
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days
        );

        marketplace.cancelJob(jobId);

        assertEq(requester.balance, balanceBefore);

        JobMarketplace.Job memory job = marketplace.getJob(jobId);
        assertTrue(job.status == JobMarketplace.JobStatus.CANCELLED);

        vm.stopPrank();
    }

    function testCancelJobWithAssignedProviders() public {
        // 1. Register providers
        vm.prank(dataProvider);
        reputationNFT.registerProvider(dataProvider);

        vm.prank(computeProvider);
        reputationNFT.registerProvider(computeProvider);

        // 2. Stake
        vm.prank(dataProvider);
        providerStaking.stake{value: MIN_DATA_STAKE}(ProviderStaking.ProviderType.DATA);

        vm.prank(computeProvider);
        providerStaking.stake{value: MIN_COMPUTE_STAKE}(ProviderStaking.ProviderType.COMPUTE);

        // 3. Create job
        vm.startPrank(requester);
        bytes32 jobId = marketplace.createJob{value: 1 ether}(
            "QmTestJobDetails",
            2000,
            7000,
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days
        );
        vm.stopPrank();

        // 4. Providers apply
        vm.prank(dataProvider);
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.DATA);

        vm.prank(computeProvider);
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.COMPUTE);

        // 5. Assign providers (this locks their stakes)
        vm.prank(requester);
        marketplace.assignProviders(jobId, dataProvider, computeProvider);

        // Verify stakes are locked
        ProviderStaking.StakeInfo memory dataStake = providerStaking.getStakeInfo(dataProvider);
        ProviderStaking.StakeInfo memory computeStake = providerStaking.getStakeInfo(computeProvider);
        assertEq(dataStake.lockedAmount, MIN_DATA_STAKE);
        assertEq(computeStake.lockedAmount, MIN_COMPUTE_STAKE);
        assertEq(dataStake.availableAmount, 0);
        assertEq(computeStake.availableAmount, 0);

        // 6. Cancel job (this should unlock stakes)
        vm.prank(requester);
        marketplace.cancelJob(jobId);

        // 7. Verify job is cancelled
        JobMarketplace.Job memory job = marketplace.getJob(jobId);
        assertTrue(job.status == JobMarketplace.JobStatus.CANCELLED);

        // 8. Verify stakes are unlocked
        dataStake = providerStaking.getStakeInfo(dataProvider);
        computeStake = providerStaking.getStakeInfo(computeProvider);
        assertEq(dataStake.lockedAmount, 0);
        assertEq(computeStake.lockedAmount, 0);
        assertEq(dataStake.availableAmount, MIN_DATA_STAKE);
        assertEq(computeStake.availableAmount, MIN_COMPUTE_STAKE);
    }

    function testCannotApplyTwice() public {
        // Register and stake
        vm.prank(dataProvider);
        reputationNFT.registerProvider(dataProvider);
        vm.prank(dataProvider);
        providerStaking.stake{value: MIN_DATA_STAKE}(ProviderStaking.ProviderType.DATA);

        // Create job
        vm.startPrank(requester);
        bytes32 jobId = marketplace.createJob{value: 1 ether}(
            "QmTestJobDetails",
            2000,
            7000,
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days
        );
        vm.stopPrank();

        // First application should succeed
        vm.prank(dataProvider);
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.DATA);

        // Second application should fail
        vm.prank(dataProvider);
        vm.expectRevert("Already applied");
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.DATA);
    }

    function testTrainingChallenge() public {
        // Setup job and providers
        vm.prank(dataProvider);
        reputationNFT.registerProvider(dataProvider);
        vm.prank(dataProvider);
        providerStaking.stake{value: MIN_DATA_STAKE}(ProviderStaking.ProviderType.DATA);

        vm.prank(computeProvider);
        reputationNFT.registerProvider(computeProvider);
        vm.prank(computeProvider);
        providerStaking.stake{value: MIN_COMPUTE_STAKE}(ProviderStaking.ProviderType.COMPUTE);

        vm.startPrank(requester);
        bytes32 jobId = marketplace.createJob{value: 1 ether}(
            "QmTestJobDetails",
            2000,
            7000,
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days
        );
        vm.stopPrank();

        vm.prank(dataProvider);
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.DATA);

        vm.prank(computeProvider);
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.COMPUTE);

        vm.prank(requester);
        marketplace.assignProviders(jobId, dataProvider, computeProvider);

        vm.prank(dataProvider);
        marketplace.uploadDataset(jobId, "QmEncryptedDataset");

        vm.prank(computeProvider);
        marketplace.submitTraining(jobId, "QmTrainedModel", "QmMetrics");

        // Challenge the training
        address challenger = makeAddr("challenger");
        vm.prank(challenger);
        trainingVerification.challengeTraining(jobId, "Model metrics are suspicious");

        TrainingVerification.VerificationStatus status = trainingVerification.getVerificationStatus(jobId);
        assertTrue(status == TrainingVerification.VerificationStatus.DISPUTED);
    }
}
