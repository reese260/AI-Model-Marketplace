// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./ReputationMath.sol";

/**
 * @title ReputationNFT
 * @notice Advanced on-chain reputation system using exponential moving averages and time decay
 * @dev Each provider gets one NFT that tracks their reputation score and job history
 *
 * REPUTATION SYSTEM OVERVIEW:
 * ===========================
 * This contract implements a sophisticated reputation system that goes beyond simple
 * +/- point adjustments. It uses advanced mathematical models to provide fair,
 * context-aware reputation scoring.
 *
 * KEY FEATURES:
 * 1. Exponential Moving Average (EMA): Recent jobs matter more
 * 2. Time-based decay: Old reputation degrades over time
 * 3. Job value weighting: Bigger jobs have more impact
 * 4. Statistical confidence scoring: Accounts for sample size
 *
 * REPUTATION SCORE RANGE:
 * - Minimum: 0 (completely unreliable)
 * - Starting: 500 (neutral, no history)
 * - Maximum: 1000 (perfect track record)
 *
 * MATHEMATICAL APPROACH:
 * Instead of: score += 10 (success) or score -= 20 (failure)
 * We use: newScore = EMA(oldScore, jobScore, jobValue)
 * Where jobScore = 900 for success, 100 for failure
 *
 * This ensures:
 * - High-value jobs have proportionally more impact
 * - Reputation smoothly adapts to performance
 * - Recent performance weighted more than old jobs
 * - Statistically sound confidence measures
 *
 * See ReputationMath.sol for detailed mathematical documentation
 */
contract ReputationNFT is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    struct ReputationData {
        uint256 score;              // Reputation score (0-1000)
        uint256 totalJobsCompleted; // Total jobs successfully completed
        uint256 totalJobsFailed;    // Total jobs failed or disputed
        uint256 totalStakeSlashed;  // Total amount of stake slashed
        uint256 registrationTime;   // When the provider registered
        uint256 lastUpdateTime;     // Last time reputation was updated (for decay calculation)
        uint256 zkProofsSubmitted;  // Number of ZK proofs submitted
    }

    // Token ID counter
    uint256 private _tokenIdCounter;

    // Mapping from token ID to reputation data
    mapping(uint256 => ReputationData) public reputationData;

    // Mapping from provider address to token ID
    mapping(address => uint256) public providerToTokenId;

    // Authorized contracts that can update reputation
    mapping(address => bool) public authorizedUpdaters;

    /// @notice Job score for successful completion (0-1000 scale)
    /// @dev High score (900) gives strong positive reputation impact
    uint256 constant SUCCESS_SCORE = 900;

    /// @notice Job score for failed/disputed jobs (0-1000 scale)
    /// @dev Low score (100) gives strong negative reputation impact
    uint256 constant FAILURE_SCORE = 100;

    /// @notice ZK proof bonus percentage for reputation (basis points)
    /// @dev Submitting ZK proof gives 5% bonus to reputation impact
    uint256 constant ZK_BONUS_BPS = 500;

    // Events
    event ProviderRegistered(address indexed provider, uint256 indexed tokenId);
    event ReputationUpdated(
        uint256 indexed tokenId,
        uint256 oldScore,
        uint256 newScore,
        bool isSuccess,
        uint256 jobValue
    );
    event ReputationUpdatedWithZK(
        uint256 indexed tokenId,
        uint256 oldScore,
        uint256 newScore,
        bool isSuccess,
        uint256 jobValue,
        uint256 zkProofsSubmitted
    );
    event UpdaterAuthorized(address indexed updater, bool authorized);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("AI Marketplace Reputation", "AIMR");
        __Ownable_init(msg.sender);
        _tokenIdCounter = 1; // Start from 1, 0 means not registered
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Self-register as a provider and mint a reputation NFT
     * @return tokenId The ID of the newly minted reputation NFT
     */
    function registerSelf() external returns (uint256) {
        return _registerProvider(msg.sender);
    }

    /**
     * @notice Register a new provider and mint them a reputation NFT (authorized callers only)
     * @param provider Address of the provider to register
     * @return tokenId The ID of the newly minted reputation NFT
     */
    function registerProvider(address provider) external returns (uint256) {
        require(authorizedUpdaters[msg.sender], "Not authorized to register");
        return _registerProvider(provider);
    }

    function _registerProvider(address provider) internal returns (uint256) {
        require(providerToTokenId[provider] == 0, "Provider already registered");

        uint256 tokenId = _tokenIdCounter++;
        _safeMint(provider, tokenId);

        providerToTokenId[provider] = tokenId;
        reputationData[tokenId] = ReputationData({
            score: 500,  // Start with neutral score
            totalJobsCompleted: 0,
            totalJobsFailed: 0,
            totalStakeSlashed: 0,
            registrationTime: block.timestamp,
            lastUpdateTime: block.timestamp,
            zkProofsSubmitted: 0
        });

        emit ProviderRegistered(provider, tokenId);
        return tokenId;
    }

    /**
     * @notice Update provider reputation after job completion using advanced EMA scoring
     * @param provider Address of the provider
     * @param isSuccess Whether the job was successful
     * @param jobValue Payment value of the job (used for weighted reputation updates)
     * @param stakeSlashed Amount of stake slashed (if any)
     */
    function updateReputation(
        address provider,
        bool isSuccess,
        uint256 jobValue,
        uint256 stakeSlashed
    ) external {
        require(authorizedUpdaters[msg.sender], "Not authorized to update reputation");

        uint256 tokenId = providerToTokenId[provider];
        require(tokenId != 0, "Provider not registered");

        ReputationData storage data = reputationData[tokenId];

        // Store old score for event emission
        uint256 oldScore = data.score;

        // Step 1: Apply time decay to current reputation
        // Calculate days elapsed since last update
        uint256 daysElapsed = (block.timestamp - data.lastUpdateTime) / 1 days;

        // Apply exponential time decay if time has passed
        if (daysElapsed > 0) {
            data.score = ReputationMath.calculateTimeDecay(data.score, daysElapsed);
        }

        // Step 2: Determine job score based on success/failure
        uint256 jobScore = isSuccess ? SUCCESS_SCORE : FAILURE_SCORE;

        // Step 3: Update reputation using Exponential Moving Average
        // Higher job values have more impact on reputation
        data.score = ReputationMath.updateReputationEMA(
            data.score,
            jobScore,
            jobValue
        );

        // Step 4: Update historical statistics
        if (isSuccess) {
            data.totalJobsCompleted++;
        } else {
            data.totalJobsFailed++;
        }

        if (stakeSlashed > 0) {
            data.totalStakeSlashed += stakeSlashed;
        }

        // Update timestamp for next decay calculation
        data.lastUpdateTime = block.timestamp;

        emit ReputationUpdated(tokenId, oldScore, data.score, isSuccess, jobValue);
    }

    /**
     * @notice Update provider reputation with ZK proof bonus
     * @param provider Address of the provider
     * @param isSuccess Whether the job was successful
     * @param jobValue Payment value of the job
     * @param stakeSlashed Amount of stake slashed (if any)
     */
    function updateReputationWithZK(
        address provider,
        bool isSuccess,
        uint256 jobValue,
        uint256 stakeSlashed
    ) external {
        require(authorizedUpdaters[msg.sender], "Not authorized to update reputation");

        uint256 tokenId = providerToTokenId[provider];
        require(tokenId != 0, "Provider not registered");

        ReputationData storage data = reputationData[tokenId];

        // Store old score for event emission
        uint256 oldScore = data.score;

        // Step 1: Apply time decay to current reputation
        uint256 daysElapsed = (block.timestamp - data.lastUpdateTime) / 1 days;
        if (daysElapsed > 0) {
            data.score = ReputationMath.calculateTimeDecay(data.score, daysElapsed);
        }

        // Step 2: Determine job score with ZK bonus
        uint256 jobScore = isSuccess ? SUCCESS_SCORE : FAILURE_SCORE;

        // Apply ZK bonus for successful jobs (5% boost to job score impact)
        if (isSuccess) {
            // Boost effective job value to increase EMA weight
            jobValue = jobValue + (jobValue * ZK_BONUS_BPS) / 10000;
        }

        // Step 3: Update reputation using EMA
        data.score = ReputationMath.updateReputationEMA(
            data.score,
            jobScore,
            jobValue
        );

        // Step 4: Update statistics
        if (isSuccess) {
            data.totalJobsCompleted++;
        } else {
            data.totalJobsFailed++;
        }

        if (stakeSlashed > 0) {
            data.totalStakeSlashed += stakeSlashed;
        }

        // Increment ZK proofs counter
        data.zkProofsSubmitted++;

        data.lastUpdateTime = block.timestamp;

        emit ReputationUpdatedWithZK(tokenId, oldScore, data.score, isSuccess, jobValue, data.zkProofsSubmitted);
    }

    /**
     * @notice Get the number of ZK proofs submitted by a provider
     * @param provider Address of the provider
     * @return uint256 Number of ZK proofs submitted
     */
    function getZKProofsSubmitted(address provider) external view returns (uint256) {
        uint256 tokenId = providerToTokenId[provider];
        require(tokenId != 0, "Provider not registered");
        return reputationData[tokenId].zkProofsSubmitted;
    }

    /**
     * @notice Authorize or deauthorize a contract to update reputation
     * @param updater Address of the contract
     * @param authorized Whether to authorize or deauthorize
     */
    function setAuthorizedUpdater(address updater, bool authorized) external onlyOwner {
        authorizedUpdaters[updater] = authorized;
        emit UpdaterAuthorized(updater, authorized);
    }

    /**
     * @notice Get reputation data for a provider
     * @param provider Address of the provider
     * @return data The reputation data
     */
    function getProviderReputation(address provider) external view returns (ReputationData memory) {
        uint256 tokenId = providerToTokenId[provider];
        require(tokenId != 0, "Provider not registered");
        return reputationData[tokenId];
    }

    /**
     * @notice Calculate statistical confidence score for a provider
     * @param provider Address of the provider
     * @return confidence Statistical confidence score (unbounded, higher = more reliable)
     */
    function getProviderConfidenceScore(address provider) external view returns (uint256 confidence) {
        uint256 tokenId = providerToTokenId[provider];
        require(tokenId != 0, "Provider not registered");

        ReputationData memory data = reputationData[tokenId];

        return ReputationMath.calculateConfidenceScore(
            data.score,
            data.totalJobsCompleted,
            data.totalJobsFailed
        );
    }

    /**
     * @notice Check if a provider is registered
     * @param provider Address to check
     * @return bool True if registered
     */
    function isProviderRegistered(address provider) external view returns (bool) {
        return providerToTokenId[provider] != 0;
    }

    /**
     * @notice Override transfer functions to make reputation NFTs non-transferable
     */
    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        if (from != address(0) && to != address(0)) {
            revert("Reputation NFTs are non-transferable");
        }
        return super._update(to, tokenId, auth);
    }

    // Helper function
    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
