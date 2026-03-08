// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IZKVerifier.sol";

/**
 * @title TrainingVerification
 * @notice Hybrid verification system for AI model training with ZK proof support
 * @dev Training results can be verified instantly via ZK proofs or through
 *      optimistic verification with a challenge period.
 *
 * VERIFICATION MODES:
 * 1. ZK Proof (Instant): Submit proof -> immediate ZK_VERIFIED status
 * 2. Optimistic (24h): Submit -> PENDING -> wait 24h -> VERIFIED
 *
 * ZK proofs provide cryptographic guarantees that:
 * - Model was trained on the committed dataset
 * - Training computation was performed correctly
 * - Reported metrics are genuine outputs
 */
contract TrainingVerification is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    enum VerificationStatus {
        PENDING,        // Training submitted, waiting for challenge period
        ZK_VERIFIED,    // Training verified via ZK proof (instant, cannot be challenged)
        VERIFIED,       // Challenge period passed, training verified
        DISPUTED,       // Training disputed, under review
        REJECTED        // Training rejected after dispute
    }

    struct TrainingSubmission {
        bytes32 jobId;
        address computeProvider;
        string modelHashIPFS;       // IPFS hash of trained model
        string metricsHashIPFS;     // IPFS hash of training metrics
        uint256 submissionTime;
        uint256 challengeDeadline;
        VerificationStatus status;
        address challenger;
        string disputeReason;
        // ZK proof fields
        bool hasZKProof;            // Whether ZK proof was provided
        bytes32 datasetCommitment;  // Poseidon hash of dataset
        bytes32 modelCommitment;    // Commitment of model weights
        bytes32 metricsCommitment;  // Commitment of training metrics
        bytes32 proofHash;          // Hash of the ZK proof (for reference)
    }

    // Challenge period duration (e.g., 24 hours)
    uint256 public challengePeriod;

    // ZK Verifier contract reference
    IZKVerifier public zkVerifier;

    // Mapping from job ID to training submission
    mapping(bytes32 => TrainingSubmission) public submissions;

    // Authorized contracts that can submit training results
    mapping(address => bool) public authorizedSubmitters;

    // Events
    event TrainingSubmitted(
        bytes32 indexed jobId,
        address indexed computeProvider,
        string modelHashIPFS,
        uint256 challengeDeadline
    );
    event TrainingSubmittedWithZKProof(
        bytes32 indexed jobId,
        address indexed computeProvider,
        string modelHashIPFS,
        bytes32 proofHash
    );
    event TrainingChallenged(bytes32 indexed jobId, address indexed challenger, string reason);
    event TrainingVerified(bytes32 indexed jobId);
    event TrainingZKVerified(bytes32 indexed jobId, bytes32 proofHash);
    event TrainingRejected(bytes32 indexed jobId);
    event DisputeResolved(bytes32 indexed jobId, bool accepted);
    event ZKVerifierUpdated(address indexed oldVerifier, address indexed newVerifier);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _challengePeriod) public initializer {
        __Ownable_init(msg.sender);
        challengePeriod = _challengePeriod;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Submit training results for verification
     * @param jobId ID of the training job
     * @param computeProvider Address of the compute provider
     * @param modelHashIPFS IPFS hash of the trained model
     * @param metricsHashIPFS IPFS hash of training metrics
     */
    function submitTrainingResult(
        bytes32 jobId,
        address computeProvider,
        string calldata modelHashIPFS,
        string calldata metricsHashIPFS
    ) external {
        require(authorizedSubmitters[msg.sender], "Not authorized to submit");
        require(
            submissions[jobId].submissionTime == 0 || submissions[jobId].status == VerificationStatus.REJECTED,
            "Training already submitted"
        );
        require(bytes(modelHashIPFS).length > 0, "Invalid model hash");
        require(bytes(metricsHashIPFS).length > 0, "Invalid metrics hash");

        uint256 deadline = block.timestamp + challengePeriod;

        submissions[jobId] = TrainingSubmission({
            jobId: jobId,
            computeProvider: computeProvider,
            modelHashIPFS: modelHashIPFS,
            metricsHashIPFS: metricsHashIPFS,
            submissionTime: block.timestamp,
            challengeDeadline: deadline,
            status: VerificationStatus.PENDING,
            challenger: address(0),
            disputeReason: "",
            hasZKProof: false,
            datasetCommitment: bytes32(0),
            modelCommitment: bytes32(0),
            metricsCommitment: bytes32(0),
            proofHash: bytes32(0)
        });

        emit TrainingSubmitted(jobId, computeProvider, modelHashIPFS, deadline);
    }

    /**
     * @notice Submit training results with ZK proof for instant verification
     * @param jobId ID of the training job
     * @param computeProvider Address of the compute provider
     * @param modelHashIPFS IPFS hash of the trained model
     * @param metricsHashIPFS IPFS hash of training metrics
     * @param datasetCommitment Poseidon hash commitment of the dataset
     * @param modelCommitment Commitment of the trained model
     * @param metricsCommitment Commitment of the training metrics
     * @param proof The Groth16 proof
     * @param publicInputs The public inputs for the proof
     */
    function submitTrainingWithZKProof(
        bytes32 jobId,
        address computeProvider,
        string calldata modelHashIPFS,
        string calldata metricsHashIPFS,
        bytes32 datasetCommitment,
        bytes32 modelCommitment,
        bytes32 metricsCommitment,
        uint256[8] calldata proof,
        uint256[] calldata publicInputs
    ) external {
        require(authorizedSubmitters[msg.sender], "Not authorized to submit");
        require(
            submissions[jobId].submissionTime == 0 || submissions[jobId].status == VerificationStatus.REJECTED,
            "Training already submitted"
        );
        require(bytes(modelHashIPFS).length > 0, "Invalid model hash");
        require(bytes(metricsHashIPFS).length > 0, "Invalid metrics hash");
        require(address(zkVerifier) != address(0), "ZK verifier not configured");

        // Validate public inputs match commitments
        require(
            zkVerifier.validatePublicInputs(
                datasetCommitment,
                modelCommitment,
                metricsCommitment,
                publicInputs
            ),
            "Public inputs mismatch"
        );

        // Verify the ZK proof
        require(
            zkVerifier.verifyTrainingProof(jobId, proof, publicInputs),
            "ZK proof verification failed"
        );

        // Calculate proof hash
        bytes32 proofHash = keccak256(abi.encodePacked(proof, publicInputs));

        // Create submission with ZK_VERIFIED status (instant verification)
        submissions[jobId] = TrainingSubmission({
            jobId: jobId,
            computeProvider: computeProvider,
            modelHashIPFS: modelHashIPFS,
            metricsHashIPFS: metricsHashIPFS,
            submissionTime: block.timestamp,
            challengeDeadline: 0, // No challenge period for ZK-verified
            status: VerificationStatus.ZK_VERIFIED,
            challenger: address(0),
            disputeReason: "",
            hasZKProof: true,
            datasetCommitment: datasetCommitment,
            modelCommitment: modelCommitment,
            metricsCommitment: metricsCommitment,
            proofHash: proofHash
        });

        emit TrainingSubmittedWithZKProof(jobId, computeProvider, modelHashIPFS, proofHash);
        emit TrainingZKVerified(jobId, proofHash);
    }

    /**
     * @notice Challenge a training submission
     * @param jobId ID of the job to challenge
     * @param reason Reason for the challenge
     */
    function challengeTraining(bytes32 jobId, string calldata reason) external {
        TrainingSubmission storage submission = submissions[jobId];
        require(submission.submissionTime > 0, "Training not submitted");
        require(submission.status == VerificationStatus.PENDING, "Cannot challenge this submission");
        require(!submission.hasZKProof, "Cannot challenge ZK-verified submission");
        require(block.timestamp <= submission.challengeDeadline, "Challenge period expired");
        require(bytes(reason).length > 0, "Must provide challenge reason");

        submission.status = VerificationStatus.DISPUTED;
        submission.challenger = msg.sender;
        submission.disputeReason = reason;

        emit TrainingChallenged(jobId, msg.sender, reason);
    }

    /**
     * @notice Verify training after challenge period (can be called by anyone)
     * @param jobId ID of the job to verify
     */
    function verifyTraining(bytes32 jobId) external {
        TrainingSubmission storage submission = submissions[jobId];
        require(submission.submissionTime > 0, "Training not submitted");
        require(submission.status == VerificationStatus.PENDING, "Training not pending");
        require(block.timestamp > submission.challengeDeadline, "Challenge period not ended");

        submission.status = VerificationStatus.VERIFIED;
        emit TrainingVerified(jobId);
    }

    /**
     * @notice Resolve a dispute (only owner/governance)
     * @param jobId ID of the disputed job
     * @param accepted Whether to accept or reject the training
     */
    function resolveDispute(bytes32 jobId, bool accepted) external onlyOwner {
        TrainingSubmission storage submission = submissions[jobId];
        require(submission.status == VerificationStatus.DISPUTED, "Not disputed");

        if (accepted) {
            submission.status = VerificationStatus.VERIFIED;
            emit TrainingVerified(jobId);
        } else {
            submission.status = VerificationStatus.REJECTED;
            emit TrainingRejected(jobId);
        }

        emit DisputeResolved(jobId, accepted);
    }

    /**
     * @notice Authorize a contract to submit training results
     * @param submitter Address to authorize
     * @param authorized Whether to authorize
     */
    function setAuthorizedSubmitter(address submitter, bool authorized) external onlyOwner {
        authorizedSubmitters[submitter] = authorized;
    }

    /**
     * @notice Update challenge period duration
     * @param newPeriod New challenge period in seconds
     */
    function updateChallengePeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0, "Invalid period");
        challengePeriod = newPeriod;
    }

    /**
     * @notice Get verification status of a training job
     * @param jobId ID of the job
     * @return VerificationStatus Current status
     */
    function getVerificationStatus(bytes32 jobId) external view returns (VerificationStatus) {
        return submissions[jobId].status;
    }

    /**
     * @notice Check if training is verified (either via ZK proof or optimistic)
     * @param jobId ID of the job
     * @return bool True if verified
     */
    function isTrainingVerified(bytes32 jobId) external view returns (bool) {
        VerificationStatus status = submissions[jobId].status;
        return status == VerificationStatus.VERIFIED || status == VerificationStatus.ZK_VERIFIED;
    }

    /**
     * @notice Check if training was ZK verified
     * @param jobId ID of the job
     * @return bool True if ZK verified
     */
    function isZKVerified(bytes32 jobId) external view returns (bool) {
        return submissions[jobId].status == VerificationStatus.ZK_VERIFIED;
    }

    /**
     * @notice Set the ZK verifier contract address
     * @param _zkVerifier Address of the ZK verifier contract
     */
    function setZKVerifier(address _zkVerifier) external onlyOwner {
        address oldVerifier = address(zkVerifier);
        zkVerifier = IZKVerifier(_zkVerifier);
        emit ZKVerifierUpdated(oldVerifier, _zkVerifier);
    }

    /**
     * @notice Get full training submission details
     * @param jobId ID of the job
     * @return TrainingSubmission struct
     */
    function getSubmission(bytes32 jobId) external view returns (TrainingSubmission memory) {
        return submissions[jobId];
    }

    /**
     * @notice Check if challenge period is active
     * @param jobId ID of the job
     * @return bool True if still in challenge period
     */
    function isInChallengePeriod(bytes32 jobId) external view returns (bool) {
        TrainingSubmission memory submission = submissions[jobId];
        return submission.status == VerificationStatus.PENDING &&
               block.timestamp <= submission.challengeDeadline;
    }
}
