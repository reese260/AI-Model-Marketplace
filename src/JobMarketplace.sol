// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ReputationNFT.sol";
import "./ProviderStaking.sol";
import "./TrainingVerification.sol";
import "./ModelTrainingEscrow.sol";

/**
 * @title JobMarketplace
 * @notice Main contract orchestrating AI model training jobs
 * @dev Coordinates job creation, provider matching, and payment distribution
 */
contract JobMarketplace is Initializable, OwnableUpgradeable, ReentrancyGuard, UUPSUpgradeable {
    enum JobStatus {
        OPEN,           // Job posted, waiting for providers
        IN_PROGRESS,    // Providers assigned, training in progress
        SUBMITTED,      // Training submitted, verification pending
        COMPLETED,      // Training verified and payments released
        CANCELLED,      // Job cancelled
        DISPUTED        // Job under dispute
    }

    struct Job {
        bytes32 jobId;
        address requester;
        address dataProvider;
        address computeProvider;
        string jobDetailsIPFS;      // IPFS hash of job requirements
        string datasetHashIPFS;     // IPFS hash of encrypted dataset
        uint256 paymentAmount;
        uint256 requiredStakeData;  // Required stake for data provider
        uint256 requiredStakeCompute; // Required stake for compute provider
        uint256 dataProviderShare;  // Percentage in basis points
        uint256 computeProviderShare; // Percentage in basis points
        uint256 createdAt;
        uint256 deadline;           // Training deadline
        JobStatus status;
        // ZK proof fields
        bytes32 datasetCommitment;  // Poseidon hash of dataset (set when uploaded)
        bool requiresZKProof;       // Requester can mandate ZK proof
        uint256 zkProofBonus;       // Extra payment for ZK proof submission
        bool usedZKProof;           // Whether ZK proof was used for verification
    }

    // Contract references
    ReputationNFT public reputationNFT;
    ProviderStaking public providerStaking;
    TrainingVerification public trainingVerification;
    ModelTrainingEscrow public escrow;

    // Job counter for generating unique IDs
    uint256 private jobCounter;

    // Mapping from job ID to job details
    mapping(bytes32 => Job) public jobs;

    // Mapping from job ID to applicants
    mapping(bytes32 => address[]) public dataProviderApplicants;
    mapping(bytes32 => address[]) public computeProviderApplicants;

    // Mapping to track if an address has applied (jobId => provider => hasApplied)
    mapping(bytes32 => mapping(address => bool)) private dataProviderHasApplied;
    mapping(bytes32 => mapping(address => bool)) private computeProviderHasApplied;

    // Events
    event JobCreated(
        bytes32 indexed jobId,
        address indexed requester,
        uint256 paymentAmount,
        string jobDetailsIPFS
    );
    event ProviderApplied(bytes32 indexed jobId, address indexed provider, ProviderStaking.ProviderType providerType);
    event ProvidersAssigned(bytes32 indexed jobId, address dataProvider, address computeProvider);
    event DatasetUploaded(bytes32 indexed jobId, string datasetHashIPFS);
    event TrainingStarted(bytes32 indexed jobId);
    event TrainingSubmittedForVerification(bytes32 indexed jobId, string modelHashIPFS);
    event TrainingSubmittedWithZKProof(bytes32 indexed jobId, string modelHashIPFS, bytes32 proofHash);
    event JobCompleted(bytes32 indexed jobId);
    event JobCompletedWithZKBonus(bytes32 indexed jobId, uint256 zkBonus);
    event JobCancelled(bytes32 indexed jobId);
    event JobDisputed(bytes32 indexed jobId, address disputer);
    event DatasetCommitmentSet(bytes32 indexed jobId, bytes32 commitment);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _reputationNFT,
        address _providerStaking,
        address _trainingVerification,
        address _escrow
    ) public initializer {
        __Ownable_init(msg.sender);
        reputationNFT = ReputationNFT(_reputationNFT);
        providerStaking = ProviderStaking(_providerStaking);
        trainingVerification = TrainingVerification(_trainingVerification);
        escrow = ModelTrainingEscrow(_escrow);
        jobCounter = 1;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Create a new training job
     * @param jobDetailsIPFS IPFS hash containing job requirements
     * @param dataProviderShare Percentage for data provider (basis points)
     * @param computeProviderShare Percentage for compute provider (basis points)
     * @param requiredStakeData Required stake for data provider
     * @param requiredStakeCompute Required stake for compute provider
     * @param deadline Training deadline timestamp
     */
    function createJob(
        string calldata jobDetailsIPFS,
        uint256 dataProviderShare,
        uint256 computeProviderShare,
        uint256 requiredStakeData,
        uint256 requiredStakeCompute,
        uint256 deadline
    ) external payable nonReentrant returns (bytes32) {
        return _createJob(
            jobDetailsIPFS,
            dataProviderShare,
            computeProviderShare,
            requiredStakeData,
            requiredStakeCompute,
            deadline,
            false, // requiresZKProof
            0      // zkProofBonus
        );
    }

    /**
     * @notice Create a new training job with ZK proof requirements
     * @param jobDetailsIPFS IPFS hash containing job requirements
     * @param dataProviderShare Percentage for data provider (basis points)
     * @param computeProviderShare Percentage for compute provider (basis points)
     * @param requiredStakeData Required stake for data provider
     * @param requiredStakeCompute Required stake for compute provider
     * @param deadline Training deadline timestamp
     * @param requiresZKProof Whether ZK proof is mandatory
     * @param zkProofBonus Extra payment for ZK proof submission
     */
    function createJobWithZKRequirements(
        string calldata jobDetailsIPFS,
        uint256 dataProviderShare,
        uint256 computeProviderShare,
        uint256 requiredStakeData,
        uint256 requiredStakeCompute,
        uint256 deadline,
        bool requiresZKProof,
        uint256 zkProofBonus
    ) external payable nonReentrant returns (bytes32) {
        return _createJob(
            jobDetailsIPFS,
            dataProviderShare,
            computeProviderShare,
            requiredStakeData,
            requiredStakeCompute,
            deadline,
            requiresZKProof,
            zkProofBonus
        );
    }

    /**
     * @notice Internal function to create a job
     */
    function _createJob(
        string calldata jobDetailsIPFS,
        uint256 dataProviderShare,
        uint256 computeProviderShare,
        uint256 requiredStakeData,
        uint256 requiredStakeCompute,
        uint256 deadline,
        bool requiresZKProof,
        uint256 zkProofBonus
    ) internal returns (bytes32) {
        require(msg.value > 0, "Must provide payment");
        require(bytes(jobDetailsIPFS).length > 0, "Must provide job details");
        require(deadline > block.timestamp, "Invalid deadline");

        // Generate unique job ID
        bytes32 jobId = keccak256(abi.encodePacked(msg.sender, jobCounter++, block.timestamp));

        jobs[jobId] = Job({
            jobId: jobId,
            requester: msg.sender,
            dataProvider: address(0),
            computeProvider: address(0),
            jobDetailsIPFS: jobDetailsIPFS,
            datasetHashIPFS: "",
            paymentAmount: msg.value,
            requiredStakeData: requiredStakeData,
            requiredStakeCompute: requiredStakeCompute,
            dataProviderShare: dataProviderShare,
            computeProviderShare: computeProviderShare,
            createdAt: block.timestamp,
            deadline: deadline,
            status: JobStatus.OPEN,
            datasetCommitment: bytes32(0),
            requiresZKProof: requiresZKProof,
            zkProofBonus: zkProofBonus,
            usedZKProof: false
        });

        emit JobCreated(jobId, msg.sender, msg.value, jobDetailsIPFS);
        return jobId;
    }

    /**
     * @notice Apply to be a provider for a job
     * @param jobId ID of the job to apply for
     * @param providerType Type of provider (DATA or COMPUTE)
     */
    function applyForJob(bytes32 jobId, ProviderStaking.ProviderType providerType) external {
        Job storage job = jobs[jobId];
        require(job.status == JobStatus.OPEN, "Job not open");
        require(reputationNFT.isProviderRegistered(msg.sender), "Provider not registered");

        // Check stake requirements
        ProviderStaking.StakeInfo memory stakeInfo = providerStaking.getStakeInfo(msg.sender);
        require(stakeInfo.providerType == providerType, "Wrong provider type");

        if (providerType == ProviderStaking.ProviderType.DATA) {
            require(stakeInfo.availableAmount >= job.requiredStakeData, "Insufficient stake");
            require(!dataProviderHasApplied[jobId][msg.sender], "Already applied");
            dataProviderApplicants[jobId].push(msg.sender);
            dataProviderHasApplied[jobId][msg.sender] = true;
        } else {
            require(stakeInfo.availableAmount >= job.requiredStakeCompute, "Insufficient stake");
            require(!computeProviderHasApplied[jobId][msg.sender], "Already applied");
            computeProviderApplicants[jobId].push(msg.sender);
            computeProviderHasApplied[jobId][msg.sender] = true;
        }

        emit ProviderApplied(jobId, msg.sender, providerType);
    }

    /**
     * @notice Assign providers to a job (called by requester)
     * @param jobId ID of the job
     * @param dataProvider Address of selected data provider
     * @param computeProvider Address of selected compute provider
     */
    function assignProviders(
        bytes32 jobId,
        address dataProvider,
        address computeProvider
    ) external nonReentrant {
        Job storage job = jobs[jobId];
        require(msg.sender == job.requester, "Only requester can assign");
        require(job.status == JobStatus.OPEN, "Job not open");
        require(dataProvider != address(0) && computeProvider != address(0), "Invalid providers");

        require(dataProviderHasApplied[jobId][dataProvider], "Data provider not applied");
        require(computeProviderHasApplied[jobId][computeProvider], "Compute provider not applied");

        job.dataProvider = dataProvider;
        job.computeProvider = computeProvider;
        job.status = JobStatus.IN_PROGRESS;

        // Lock stakes
        providerStaking.lockStake(dataProvider, job.requiredStakeData, jobId);
        providerStaking.lockStake(computeProvider, job.requiredStakeCompute, jobId);

        // Create escrow (with ZK bonus if applicable)
        if (job.zkProofBonus > 0) {
            escrow.createEscrowWithZKBonus{value: job.paymentAmount}(
                jobId,
                job.requester,
                dataProvider,
                computeProvider,
                job.dataProviderShare,
                job.computeProviderShare,
                job.zkProofBonus
            );
        } else {
            escrow.createEscrow{value: job.paymentAmount}(
                jobId,
                job.requester,
                dataProvider,
                computeProvider,
                job.dataProviderShare,
                job.computeProviderShare
            );
        }

        emit ProvidersAssigned(jobId, dataProvider, computeProvider);
    }

    /**
     * @notice Upload encrypted dataset (called by data provider)
     * @param jobId ID of the job
     * @param datasetHashIPFS IPFS hash of encrypted dataset
     */
    function uploadDataset(bytes32 jobId, string calldata datasetHashIPFS) external {
        Job storage job = jobs[jobId];
        require(msg.sender == job.dataProvider, "Only assigned data provider");
        require(job.status == JobStatus.IN_PROGRESS, "Job not in progress");
        require(bytes(datasetHashIPFS).length > 0, "Invalid dataset hash");

        job.datasetHashIPFS = datasetHashIPFS;
        emit DatasetUploaded(jobId, datasetHashIPFS);
        emit TrainingStarted(jobId);
    }

    /**
     * @notice Upload encrypted dataset with commitment for ZK verification
     * @param jobId ID of the job
     * @param datasetHashIPFS IPFS hash of encrypted dataset
     * @param datasetCommitment Poseidon hash commitment of the dataset
     */
    function uploadDatasetWithCommitment(
        bytes32 jobId,
        string calldata datasetHashIPFS,
        bytes32 datasetCommitment
    ) external {
        Job storage job = jobs[jobId];
        require(msg.sender == job.dataProvider, "Only assigned data provider");
        require(job.status == JobStatus.IN_PROGRESS, "Job not in progress");
        require(bytes(datasetHashIPFS).length > 0, "Invalid dataset hash");
        require(datasetCommitment != bytes32(0), "Invalid dataset commitment");

        job.datasetHashIPFS = datasetHashIPFS;
        job.datasetCommitment = datasetCommitment;

        emit DatasetUploaded(jobId, datasetHashIPFS);
        emit DatasetCommitmentSet(jobId, datasetCommitment);
        emit TrainingStarted(jobId);
    }

    /**
     * @notice Submit training results (called by compute provider)
     * @param jobId ID of the job
     * @param modelHashIPFS IPFS hash of trained model
     * @param metricsHashIPFS IPFS hash of training metrics
     */
    function submitTraining(
        bytes32 jobId,
        string calldata modelHashIPFS,
        string calldata metricsHashIPFS
    ) external {
        Job storage job = jobs[jobId];
        require(msg.sender == job.computeProvider, "Only assigned compute provider");
        require(job.status == JobStatus.IN_PROGRESS, "Job not in progress");
        require(bytes(job.datasetHashIPFS).length > 0, "Dataset not uploaded");
        require(!job.requiresZKProof, "This job requires ZK proof");

        job.status = JobStatus.SUBMITTED;

        // Submit to verification contract
        trainingVerification.submitTrainingResult(jobId, msg.sender, modelHashIPFS, metricsHashIPFS);

        emit TrainingSubmittedForVerification(jobId, modelHashIPFS);
    }

    /**
     * @notice Submit training results with ZK proof for instant verification
     * @param jobId ID of the job
     * @param modelHashIPFS IPFS hash of trained model
     * @param metricsHashIPFS IPFS hash of training metrics
     * @param modelCommitment Commitment of the trained model
     * @param metricsCommitment Commitment of the training metrics
     * @param proof The Groth16 proof
     * @param publicInputs The public inputs for the proof
     */
    function submitTrainingWithProof(
        bytes32 jobId,
        string calldata modelHashIPFS,
        string calldata metricsHashIPFS,
        bytes32 modelCommitment,
        bytes32 metricsCommitment,
        uint256[8] calldata proof,
        uint256[] calldata publicInputs
    ) external {
        Job storage job = jobs[jobId];
        require(msg.sender == job.computeProvider, "Only assigned compute provider");
        require(job.status == JobStatus.IN_PROGRESS, "Job not in progress");
        require(bytes(job.datasetHashIPFS).length > 0, "Dataset not uploaded");
        require(job.datasetCommitment != bytes32(0), "Dataset commitment not set");

        job.status = JobStatus.SUBMITTED;
        job.usedZKProof = true;

        // Submit to verification contract with ZK proof
        trainingVerification.submitTrainingWithZKProof(
            jobId,
            msg.sender,
            modelHashIPFS,
            metricsHashIPFS,
            job.datasetCommitment,
            modelCommitment,
            metricsCommitment,
            proof,
            publicInputs
        );

        bytes32 proofHash = keccak256(abi.encodePacked(proof, publicInputs));
        emit TrainingSubmittedWithZKProof(jobId, modelHashIPFS, proofHash);
    }

    /**
     * @notice Finalize job after verification passed
     * @param jobId ID of the job
     */
    function finalizeJob(bytes32 jobId) external nonReentrant {
        Job storage job = jobs[jobId];
        require(job.status == JobStatus.SUBMITTED, "Job not submitted");
        require(trainingVerification.isTrainingVerified(jobId), "Training not verified");

        job.status = JobStatus.COMPLETED;

        // Unlock stakes
        providerStaking.unlockStake(job.dataProvider, job.requiredStakeData, jobId);
        providerStaking.unlockStake(job.computeProvider, job.requiredStakeCompute, jobId);

        // Determine if ZK proof was used and apply bonus
        bool usedZK = job.usedZKProof || trainingVerification.isZKVerified(jobId);
        uint256 zkBonus = usedZK ? job.zkProofBonus : 0;

        // Update reputations (using job payment amount for value-weighted reputation)
        // Pass zkBonus indicator for ZK proof tracking
        reputationNFT.updateReputation(job.dataProvider, true, job.paymentAmount, 0);
        if (usedZK) {
            reputationNFT.updateReputationWithZK(job.computeProvider, true, job.paymentAmount, 0);
        } else {
            reputationNFT.updateReputation(job.computeProvider, true, job.paymentAmount, 0);
        }

        // Complete and release escrow with ZK bonus if applicable
        escrow.completeEscrow(jobId);
        escrow.releaseEscrow(jobId, usedZK);

        if (usedZK && zkBonus > 0) {
            emit JobCompletedWithZKBonus(jobId, zkBonus);
        } else {
            emit JobCompleted(jobId);
        }
    }

    /**
     * @notice Cancel job
     * @param jobId ID of the job
     */
    function cancelJob(bytes32 jobId) external nonReentrant {
        Job storage job = jobs[jobId];
        require(msg.sender == job.requester, "Only requester can cancel");
        require(
            job.status == JobStatus.OPEN ||
            job.status == JobStatus.IN_PROGRESS ||
            job.status == JobStatus.SUBMITTED,
            "Cannot cancel completed or disputed jobs"
        );

        JobStatus oldStatus = job.status;
        job.status = JobStatus.CANCELLED;

        // Unlock stakes if providers were assigned
        if (job.dataProvider != address(0)) {
            providerStaking.unlockStake(job.dataProvider, job.requiredStakeData, jobId);
        }
        if (job.computeProvider != address(0)) {
            providerStaking.unlockStake(job.computeProvider, job.requiredStakeCompute, jobId);
        }

        // Cancel escrow if it exists (for IN_PROGRESS or SUBMITTED status)
        if (oldStatus != JobStatus.OPEN && (job.dataProvider != address(0) || job.computeProvider != address(0))) {
            escrow.refundEscrow(jobId);
        } else {
            // Refund payment directly if job was still OPEN
            (bool success, ) = job.requester.call{value: job.paymentAmount}("");
            require(success, "Refund failed");
        }

        emit JobCancelled(jobId);
    }

    /**
     * @notice Dispute a job
     * @param jobId ID of the job
     */
    function disputeJob(bytes32 jobId) external {
        Job storage job = jobs[jobId];
        require(
            msg.sender == job.requester ||
            msg.sender == job.dataProvider ||
            msg.sender == job.computeProvider,
            "Not authorized"
        );
        require(
            job.status == JobStatus.IN_PROGRESS || job.status == JobStatus.SUBMITTED,
            "Cannot dispute"
        );

        job.status = JobStatus.DISPUTED;
        escrow.disputeEscrow(jobId);

        emit JobDisputed(jobId, msg.sender);
    }

    /**
     * @notice Get job details
     * @param jobId ID of the job
     * @return Job struct
     */
    function getJob(bytes32 jobId) external view returns (Job memory) {
        return jobs[jobId];
    }

    /**
     * @notice Get applicants for a job
     * @param jobId ID of the job
     * @return dataApplicants Array of data provider applicants
     * @return computeApplicants Array of compute provider applicants
     */
    function getJobApplicants(bytes32 jobId)
        external
        view
        returns (address[] memory dataApplicants, address[] memory computeApplicants)
    {
        return (dataProviderApplicants[jobId], computeProviderApplicants[jobId]);
    }
}
