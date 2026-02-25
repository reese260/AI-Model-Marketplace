// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/JobMarketplace.sol";
import "../src/ReputationNFT.sol";
import "../src/ProviderStaking.sol";
import "../src/TrainingVerification.sol";
import "../src/ModelTrainingEscrow.sol";
import "../src/ZKTrainingVerifier.sol";
import "../src/Groth16Verifier.sol";
import "./mocks/MockZKVerifier.sol";

/**
 * @title ZKVerificationTest
 * @notice Comprehensive tests for ZK proof verification system
 */
contract ZKVerificationTest is Test {
    JobMarketplace public marketplace;
    ReputationNFT public reputationNFT;
    ProviderStaking public providerStaking;
    TrainingVerification public trainingVerification;
    ModelTrainingEscrow public escrow;
    MockZKVerifier public mockZKVerifier;
    Groth16Verifier public groth16Verifier;
    ZKTrainingVerifier public zkTrainingVerifier;

    address public owner;
    address public requester;
    address public dataProvider;
    address public computeProvider;
    address public feeRecipient;

    uint256 constant MIN_DATA_STAKE = 0.1 ether;
    uint256 constant MIN_COMPUTE_STAKE = 0.5 ether;
    uint256 constant CHALLENGE_PERIOD = 24 hours;
    uint256 constant PLATFORM_FEE = 1000; // 10%

    // Test commitments
    bytes32 constant TEST_DATASET_COMMITMENT = bytes32(uint256(0x1234));
    bytes32 constant TEST_MODEL_COMMITMENT = bytes32(uint256(0x5678));
    bytes32 constant TEST_METRICS_COMMITMENT = bytes32(uint256(0x9abc));

    // Test proof (dummy values within field)
    uint256[8] testProof;
    uint256[] testPublicInputs;

    function setUp() public {
        owner = address(this);
        requester = makeAddr("requester");
        dataProvider = makeAddr("dataProvider");
        computeProvider = makeAddr("computeProvider");
        feeRecipient = makeAddr("feeRecipient");

        // Deploy core contracts via proxy
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

        // Deploy ZK contracts
        groth16Verifier = new Groth16Verifier();
        zkTrainingVerifier = ZKTrainingVerifier(address(new ERC1967Proxy(
            address(new ZKTrainingVerifier()),
            abi.encodeCall(ZKTrainingVerifier.initialize, (address(groth16Verifier)))
        )));
        mockZKVerifier = new MockZKVerifier();

        // Deploy marketplace via proxy
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

        // Set ZK verifier on training verification
        trainingVerification.setZKVerifier(address(mockZKVerifier));

        // Fund test accounts
        vm.deal(requester, 100 ether);
        vm.deal(dataProvider, 10 ether);
        vm.deal(computeProvider, 10 ether);

        // Setup test proof (small values within field)
        testProof = [
            uint256(1), uint256(2), uint256(3), uint256(4),
            uint256(5), uint256(6), uint256(7), uint256(8)
        ];

        // Setup test public inputs matching commitments
        testPublicInputs = new uint256[](3);
        testPublicInputs[0] = uint256(TEST_DATASET_COMMITMENT);
        testPublicInputs[1] = uint256(TEST_MODEL_COMMITMENT);
        testPublicInputs[2] = uint256(TEST_METRICS_COMMITMENT);
    }

    // ============ ZKTrainingVerifier Tests ============

    function testZKTrainingVerifierDeployment() public view {
        assertEq(address(zkTrainingVerifier.groth16Verifier()), address(groth16Verifier));
    }

    function testZKVerifierValidatePublicInputs() public {
        bool valid = mockZKVerifier.validatePublicInputs(
            TEST_DATASET_COMMITMENT,
            TEST_MODEL_COMMITMENT,
            TEST_METRICS_COMMITMENT,
            testPublicInputs
        );
        assertTrue(valid);
    }

    function testZKVerifierRejectsInvalidInputs() public {
        // Wrong dataset commitment
        uint256[] memory wrongInputs = new uint256[](3);
        wrongInputs[0] = uint256(bytes32(uint256(0xdead)));
        wrongInputs[1] = uint256(TEST_MODEL_COMMITMENT);
        wrongInputs[2] = uint256(TEST_METRICS_COMMITMENT);

        bool valid = mockZKVerifier.validatePublicInputs(
            TEST_DATASET_COMMITMENT,
            TEST_MODEL_COMMITMENT,
            TEST_METRICS_COMMITMENT,
            wrongInputs
        );
        assertFalse(valid);
    }

    function testZKVerifierRejectsTooFewInputs() public {
        uint256[] memory fewInputs = new uint256[](2);
        fewInputs[0] = uint256(TEST_DATASET_COMMITMENT);
        fewInputs[1] = uint256(TEST_MODEL_COMMITMENT);

        bool valid = mockZKVerifier.validatePublicInputs(
            TEST_DATASET_COMMITMENT,
            TEST_MODEL_COMMITMENT,
            TEST_METRICS_COMMITMENT,
            fewInputs
        );
        assertFalse(valid);
    }

    function testMockZKVerifierProofVerification() public {
        bytes32 jobId = keccak256("testJob");

        bool success = mockZKVerifier.verifyTrainingProof(jobId, testProof, testPublicInputs);
        assertTrue(success);
        assertEq(mockZKVerifier.verifyCallCount(), 1);
        assertEq(mockZKVerifier.lastJobId(), jobId);
    }

    function testMockZKVerifierRejectsWhenConfigured() public {
        mockZKVerifier.setShouldVerify(false);

        bytes32 jobId = keccak256("testJob");
        bool success = mockZKVerifier.verifyTrainingProof(jobId, testProof, testPublicInputs);
        assertFalse(success);
    }

    function testProofReplayPrevention() public {
        bytes32 jobId1 = keccak256("testJob1");
        bytes32 jobId2 = keccak256("testJob2");

        // First verification should succeed
        bool success1 = mockZKVerifier.verifyTrainingProof(jobId1, testProof, testPublicInputs);
        assertTrue(success1);

        // Same proof for different job should fail (replay attack)
        vm.expectRevert("Proof already used");
        mockZKVerifier.verifyTrainingProof(jobId2, testProof, testPublicInputs);
    }

    function testIsProofUsed() public {
        bytes32 proofHash = keccak256(abi.encodePacked(testProof, testPublicInputs));

        assertFalse(mockZKVerifier.isProofUsed(proofHash));

        bytes32 jobId = keccak256("testJob");
        mockZKVerifier.verifyTrainingProof(jobId, testProof, testPublicInputs);

        assertTrue(mockZKVerifier.isProofUsed(proofHash));
    }

    // ============ TrainingVerification ZK Integration Tests ============

    function testSubmitTrainingWithZKProof() public {
        // Setup
        _setupProviders();
        bytes32 jobId = _createAndSetupJob();

        // Submit with ZK proof
        vm.prank(address(marketplace));
        trainingVerification.submitTrainingWithZKProof(
            jobId,
            computeProvider,
            "QmModelHash",
            "QmMetricsHash",
            TEST_DATASET_COMMITMENT,
            TEST_MODEL_COMMITMENT,
            TEST_METRICS_COMMITMENT,
            testProof,
            testPublicInputs
        );

        // Verify status is ZK_VERIFIED
        TrainingVerification.VerificationStatus status = trainingVerification.getVerificationStatus(jobId);
        assertTrue(status == TrainingVerification.VerificationStatus.ZK_VERIFIED);

        // Verify isTrainingVerified returns true
        assertTrue(trainingVerification.isTrainingVerified(jobId));

        // Verify isZKVerified returns true
        assertTrue(trainingVerification.isZKVerified(jobId));
    }

    function testCannotChallengeZKVerifiedSubmission() public {
        // Setup
        _setupProviders();
        bytes32 jobId = _createAndSetupJob();

        // Submit with ZK proof
        vm.prank(address(marketplace));
        trainingVerification.submitTrainingWithZKProof(
            jobId,
            computeProvider,
            "QmModelHash",
            "QmMetricsHash",
            TEST_DATASET_COMMITMENT,
            TEST_MODEL_COMMITMENT,
            TEST_METRICS_COMMITMENT,
            testProof,
            testPublicInputs
        );

        // Try to challenge - should fail because status is ZK_VERIFIED, not PENDING
        address challenger = makeAddr("challenger");
        vm.prank(challenger);
        vm.expectRevert("Cannot challenge this submission");
        trainingVerification.challengeTraining(jobId, "Suspicious metrics");
    }

    function testZKSubmissionFailsWithoutVerifier() public {
        // Create new TrainingVerification without ZK verifier
        TrainingVerification tvNoZK = TrainingVerification(address(new ERC1967Proxy(
            address(new TrainingVerification()),
            abi.encodeCall(TrainingVerification.initialize, (CHALLENGE_PERIOD))
        )));
        tvNoZK.setAuthorizedSubmitter(address(this), true);

        bytes32 jobId = keccak256("noZKJob");

        vm.expectRevert("ZK verifier not configured");
        tvNoZK.submitTrainingWithZKProof(
            jobId,
            computeProvider,
            "QmModelHash",
            "QmMetricsHash",
            TEST_DATASET_COMMITMENT,
            TEST_MODEL_COMMITMENT,
            TEST_METRICS_COMMITMENT,
            testProof,
            testPublicInputs
        );
    }

    function testZKSubmissionFailsWithInvalidInputs() public {
        _setupProviders();
        bytes32 jobId = _createAndSetupJob();

        // Use magic fail commitment to trigger validation failure
        bytes32 magicFailCommitment = bytes32(uint256(0xDEAD));

        vm.prank(address(marketplace));
        vm.expectRevert("Public inputs mismatch");
        trainingVerification.submitTrainingWithZKProof(
            jobId,
            computeProvider,
            "QmModelHash",
            "QmMetricsHash",
            magicFailCommitment,  // This will cause validatePublicInputs to return false
            TEST_MODEL_COMMITMENT,
            TEST_METRICS_COMMITMENT,
            testProof,
            testPublicInputs
        );
    }

    function testZKSubmissionFailsWithInvalidProof() public {
        _setupProviders();
        bytes32 jobId = _createAndSetupJob();

        // Configure mock to reject proof
        mockZKVerifier.setShouldVerify(false);

        vm.prank(address(marketplace));
        vm.expectRevert("ZK proof verification failed");
        trainingVerification.submitTrainingWithZKProof(
            jobId,
            computeProvider,
            "QmModelHash",
            "QmMetricsHash",
            TEST_DATASET_COMMITMENT,
            TEST_MODEL_COMMITMENT,
            TEST_METRICS_COMMITMENT,
            testProof,
            testPublicInputs
        );
    }

    function testOptimisticFallbackStillWorks() public {
        _setupProviders();
        bytes32 jobId = _createAndSetupJob();

        // Submit without ZK proof (optimistic)
        vm.prank(address(marketplace));
        trainingVerification.submitTrainingResult(jobId, computeProvider, "QmModelHash", "QmMetricsHash");

        // Status should be PENDING
        TrainingVerification.VerificationStatus status = trainingVerification.getVerificationStatus(jobId);
        assertTrue(status == TrainingVerification.VerificationStatus.PENDING);

        // Not verified yet
        assertFalse(trainingVerification.isTrainingVerified(jobId));

        // Wait for challenge period
        vm.warp(block.timestamp + CHALLENGE_PERIOD + 1);

        // Verify training
        trainingVerification.verifyTraining(jobId);

        // Now it should be verified
        assertTrue(trainingVerification.isTrainingVerified(jobId));
        assertFalse(trainingVerification.isZKVerified(jobId)); // But not ZK verified
    }

    // ============ JobMarketplace ZK Integration Tests ============

    function testCreateJobWithZKRequirements() public {
        vm.startPrank(requester);
        bytes32 jobId = marketplace.createJobWithZKRequirements{value: 1 ether}(
            "QmJobDetails",
            2000,
            7000,
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days,
            true,  // requiresZKProof
            0.1 ether  // zkProofBonus
        );
        vm.stopPrank();

        JobMarketplace.Job memory job = marketplace.getJob(jobId);
        assertTrue(job.requiresZKProof);
        assertEq(job.zkProofBonus, 0.1 ether);
    }

    function testUploadDatasetWithCommitment() public {
        _setupProviders();
        bytes32 jobId = _createJobWithZK();
        _applyAndAssignProviders(jobId);

        // Upload with commitment
        vm.prank(dataProvider);
        marketplace.uploadDatasetWithCommitment(jobId, "QmDataset", TEST_DATASET_COMMITMENT);

        JobMarketplace.Job memory job = marketplace.getJob(jobId);
        assertEq(job.datasetCommitment, TEST_DATASET_COMMITMENT);
    }

    function testSubmitTrainingWithProofRequiresCommitment() public {
        _setupProviders();
        bytes32 jobId = _createJobWithZK();
        _applyAndAssignProviders(jobId);

        // Upload without commitment
        vm.prank(dataProvider);
        marketplace.uploadDataset(jobId, "QmDataset");

        // Try to submit with proof - should fail
        vm.prank(computeProvider);
        vm.expectRevert("Dataset commitment not set");
        marketplace.submitTrainingWithProof(
            jobId,
            "QmModel",
            "QmMetrics",
            TEST_MODEL_COMMITMENT,
            TEST_METRICS_COMMITMENT,
            testProof,
            testPublicInputs
        );
    }

    function testCannotSubmitOptimisticWhenZKRequired() public {
        _setupProviders();
        bytes32 jobId = _createJobWithZK();
        _applyAndAssignProviders(jobId);

        vm.prank(dataProvider);
        marketplace.uploadDatasetWithCommitment(jobId, "QmDataset", TEST_DATASET_COMMITMENT);

        // Try optimistic submission on ZK-required job
        vm.prank(computeProvider);
        vm.expectRevert("This job requires ZK proof");
        marketplace.submitTraining(jobId, "QmModel", "QmMetrics");
    }

    function testFullZKWorkflow() public {
        _setupProviders();

        // Create job with ZK bonus
        vm.startPrank(requester);
        bytes32 jobId = marketplace.createJobWithZKRequirements{value: 1.1 ether}(
            "QmJobDetails",
            2000,
            7000,
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days,
            true,
            0.1 ether
        );
        vm.stopPrank();

        _applyAndAssignProviders(jobId);

        // Upload dataset with commitment
        vm.prank(dataProvider);
        marketplace.uploadDatasetWithCommitment(jobId, "QmDataset", TEST_DATASET_COMMITMENT);

        // Submit training with ZK proof
        vm.prank(computeProvider);
        marketplace.submitTrainingWithProof(
            jobId,
            "QmModel",
            "QmMetrics",
            TEST_MODEL_COMMITMENT,
            TEST_METRICS_COMMITMENT,
            testProof,
            testPublicInputs
        );

        // Verify status is SUBMITTED and ZK verified
        JobMarketplace.Job memory job = marketplace.getJob(jobId);
        assertTrue(job.status == JobMarketplace.JobStatus.SUBMITTED);
        assertTrue(job.usedZKProof);

        // Training should be verified immediately (no waiting)
        assertTrue(trainingVerification.isTrainingVerified(jobId));
        assertTrue(trainingVerification.isZKVerified(jobId));

        // Finalize job
        uint256 computeBalanceBefore = computeProvider.balance;

        marketplace.finalizeJob(jobId);

        // Check compute provider got the ZK bonus
        uint256 baseAmount = 1 ether; // 1.1 ETH - 0.1 ETH ZK bonus
        uint256 expectedComputePayment = (baseAmount * 7000) / 10000 + 0.1 ether; // 0.7 + 0.1 = 0.8 ETH
        assertEq(computeProvider.balance, computeBalanceBefore + expectedComputePayment);

        // Check ZK proofs counter was incremented
        assertEq(reputationNFT.getZKProofsSubmitted(computeProvider), 1);
    }

    function testFullOptimisticWorkflow() public {
        _setupProviders();

        // Create job without ZK requirement
        vm.startPrank(requester);
        bytes32 jobId = marketplace.createJob{value: 1 ether}(
            "QmJobDetails",
            2000,
            7000,
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days
        );
        vm.stopPrank();

        _applyAndAssignProviders(jobId);

        // Upload dataset (without commitment)
        vm.prank(dataProvider);
        marketplace.uploadDataset(jobId, "QmDataset");

        // Submit training (optimistic)
        vm.prank(computeProvider);
        marketplace.submitTraining(jobId, "QmModel", "QmMetrics");

        // Not verified yet
        assertFalse(trainingVerification.isTrainingVerified(jobId));

        // Wait for challenge period
        vm.warp(block.timestamp + CHALLENGE_PERIOD + 1);
        trainingVerification.verifyTraining(jobId);

        // Now finalize
        marketplace.finalizeJob(jobId);

        JobMarketplace.Job memory job = marketplace.getJob(jobId);
        assertTrue(job.status == JobMarketplace.JobStatus.COMPLETED);

        // ZK proofs counter should be 0
        assertEq(reputationNFT.getZKProofsSubmitted(computeProvider), 0);
    }

    // ============ ReputationNFT ZK Tests ============

    function testReputationZKTracking() public {
        // Register provider
        vm.prank(computeProvider);
        reputationNFT.registerProvider(computeProvider);

        // Update with ZK
        reputationNFT.setAuthorizedUpdater(address(this), true);
        reputationNFT.updateReputationWithZK(computeProvider, true, 1 ether, 0);

        // Check ZK counter
        assertEq(reputationNFT.getZKProofsSubmitted(computeProvider), 1);

        // Normal update shouldn't increment
        reputationNFT.updateReputation(computeProvider, true, 1 ether, 0);
        assertEq(reputationNFT.getZKProofsSubmitted(computeProvider), 1);

        // Another ZK update
        reputationNFT.updateReputationWithZK(computeProvider, true, 1 ether, 0);
        assertEq(reputationNFT.getZKProofsSubmitted(computeProvider), 2);
    }

    // ============ Helper Functions ============

    function _setupProviders() internal {
        vm.prank(dataProvider);
        reputationNFT.registerProvider(dataProvider);
        vm.prank(dataProvider);
        providerStaking.stake{value: MIN_DATA_STAKE}(ProviderStaking.ProviderType.DATA);

        vm.prank(computeProvider);
        reputationNFT.registerProvider(computeProvider);
        vm.prank(computeProvider);
        providerStaking.stake{value: MIN_COMPUTE_STAKE}(ProviderStaking.ProviderType.COMPUTE);
    }

    function _createAndSetupJob() internal returns (bytes32) {
        vm.startPrank(requester);
        bytes32 jobId = marketplace.createJob{value: 1 ether}(
            "QmJobDetails",
            2000,
            7000,
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days
        );
        vm.stopPrank();
        return jobId;
    }

    function _createJobWithZK() internal returns (bytes32) {
        vm.startPrank(requester);
        bytes32 jobId = marketplace.createJobWithZKRequirements{value: 1 ether}(
            "QmJobDetails",
            2000,
            7000,
            MIN_DATA_STAKE,
            MIN_COMPUTE_STAKE,
            block.timestamp + 7 days,
            true,
            0
        );
        vm.stopPrank();
        return jobId;
    }

    function _applyAndAssignProviders(bytes32 jobId) internal {
        vm.prank(dataProvider);
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.DATA);

        vm.prank(computeProvider);
        marketplace.applyForJob(jobId, ProviderStaking.ProviderType.COMPUTE);

        vm.prank(requester);
        marketplace.assignProviders(jobId, dataProvider, computeProvider);
    }
}
