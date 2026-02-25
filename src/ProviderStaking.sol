// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./SlashingMath.sol";
import "./ReputationNFT.sol";

/**
 * @title ProviderStaking
 * @notice Advanced collateral staking with risk-weighted slashing penalties
 * @dev Implements sophisticated slashing using sigmoid severity curves and exponential repeat offender penalties
 *
 * STAKING SYSTEM OVERVIEW:
 * ========================
 * Providers must stake collateral to participate in the marketplace. This contract manages:
 * 1. Stake deposits and withdrawals (with minimum requirements)
 * 2. Stake locking for active jobs
 * 3. Advanced risk-weighted slashing for violations
 *
 * SLASHING PHILOSOPHY:
 * ===================
 * Traditional approach: Fixed penalty amounts (e.g., "slash 1 ETH")
 * Our approach: Context-aware penalties that consider:
 *
 * 1. SEVERITY: How bad was the violation?
 *    - Uses sigmoid curve for smooth scaling
 *    - Minor infractions → minimal penalty
 *    - Critical violations → heavy penalty
 *
 * 2. REPEAT OFFENSES: Is this a pattern of bad behavior?
 *    - Exponential growth: 1.5^(violationCount)
 *    - First offense: standard penalty
 *    - Repeat offenses: compounding penalties (up to 5x)
 *
 * 3. REPUTATION: How trusted is this provider?
 *    - Low reputation → higher penalty (untrusted)
 *    - High reputation → lower penalty (benefit of doubt)
 *
 * 4. STAKE AT RISK: How much exposure?
 *    - Square root scaling of stake ratio
 *    - Fair treatment across different stake sizes
 *
 * MATHEMATICAL FORMULA:
 * finalSlash = baseAmount × σ(severity) × (1.5)^violations × repAdjust × sqrt(stakeRatio)
 *
 * See SlashingMath.sol for comprehensive mathematical documentation
 */
contract ProviderStaking is Initializable, OwnableUpgradeable, ReentrancyGuard, UUPSUpgradeable {
    enum ProviderType { DATA, COMPUTE }

    struct StakeInfo {
        uint256 amount;           // Total staked amount
        uint256 lockedAmount;     // Amount locked for active jobs
        uint256 availableAmount;  // Amount available to withdraw
        ProviderType providerType; // Type of provider
        bool isActive;            // Whether the provider is active
        uint256 violationCount;   // Number of violations (for repeat offender penalties)
    }

    // Minimum stake required for each provider type
    uint256 public minDataProviderStake;
    uint256 public minComputeProviderStake;

    // Mapping from provider address to stake info
    mapping(address => StakeInfo) public stakes;

    // Authorized contracts that can lock/unlock stakes
    mapping(address => bool) public authorizedContracts;

    // Reputation NFT contract (for reputation-weighted slashing)
    ReputationNFT public reputationNFT;

    // Events
    event Staked(address indexed provider, uint256 amount, ProviderType providerType);
    event Unstaked(address indexed provider, uint256 amount);
    event StakeLocked(address indexed provider, uint256 amount, bytes32 indexed jobId);
    event StakeUnlocked(address indexed provider, uint256 amount, bytes32 indexed jobId);
    event StakeSlashed(address indexed provider, uint256 amount, bytes32 indexed jobId);
    event StakeSlashedAdvanced(
        address indexed provider,
        uint256 baseAmount,
        uint256 finalAmount,
        uint256 severity,
        uint256 violationCount,
        bytes32 indexed jobId
    );
    event ContractAuthorized(address indexed contractAddress, bool authorized);
    event ReputationNFTUpdated(address indexed newReputationNFT);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _minDataProviderStake, uint256 _minComputeProviderStake) public initializer {
        __Ownable_init(msg.sender);
        minDataProviderStake = _minDataProviderStake;
        minComputeProviderStake = _minComputeProviderStake;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Stake tokens to become a provider
     * @param providerType Type of provider (DATA or COMPUTE)
     */
    function stake(ProviderType providerType) external payable nonReentrant {
        require(msg.value > 0, "Must stake non-zero amount");

        uint256 minStake = providerType == ProviderType.DATA
            ? minDataProviderStake
            : minComputeProviderStake;

        StakeInfo storage stakeInfo = stakes[msg.sender];

        if (stakeInfo.amount == 0) {
            // New staker
            require(msg.value >= minStake, "Insufficient stake amount");
            stakeInfo.providerType = providerType;
        } else {
            // Existing staker adding more
            require(stakeInfo.providerType == providerType, "Cannot change provider type");
        }

        stakeInfo.amount += msg.value;
        stakeInfo.availableAmount += msg.value;
        stakeInfo.isActive = true;

        emit Staked(msg.sender, msg.value, providerType);
    }

    /**
     * @notice Unstake available tokens
     * @param amount Amount to unstake
     */
    function unstake(uint256 amount) external nonReentrant {
        StakeInfo storage stakeInfo = stakes[msg.sender];
        require(stakeInfo.amount > 0, "No stake to withdraw");
        require(amount <= stakeInfo.availableAmount, "Insufficient available stake");

        uint256 minStake = stakeInfo.providerType == ProviderType.DATA
            ? minDataProviderStake
            : minComputeProviderStake;

        uint256 remainingStake = stakeInfo.amount - amount;
        require(
            remainingStake == 0 || remainingStake >= minStake,
            "Remaining stake below minimum"
        );

        stakeInfo.amount -= amount;
        stakeInfo.availableAmount -= amount;

        if (stakeInfo.amount == 0) {
            stakeInfo.isActive = false;
        }

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, amount);
    }

    /**
     * @notice Lock stake for an active job (only authorized contracts)
     * @param provider Address of the provider
     * @param amount Amount to lock
     * @param jobId ID of the job
     */
    function lockStake(address provider, uint256 amount, bytes32 jobId) external {
        require(authorizedContracts[msg.sender], "Not authorized");

        StakeInfo storage stakeInfo = stakes[provider];
        require(stakeInfo.isActive, "Provider not active");
        require(amount <= stakeInfo.availableAmount, "Insufficient available stake");

        stakeInfo.availableAmount -= amount;
        stakeInfo.lockedAmount += amount;

        emit StakeLocked(provider, amount, jobId);
    }

    /**
     * @notice Unlock stake after job completion (only authorized contracts)
     * @param provider Address of the provider
     * @param amount Amount to unlock
     * @param jobId ID of the job
     */
    function unlockStake(address provider, uint256 amount, bytes32 jobId) external {
        require(authorizedContracts[msg.sender], "Not authorized");

        StakeInfo storage stakeInfo = stakes[provider];
        require(amount <= stakeInfo.lockedAmount, "Insufficient locked stake");

        stakeInfo.lockedAmount -= amount;
        stakeInfo.availableAmount += amount;

        emit StakeUnlocked(provider, amount, jobId);
    }

    /**
     * @notice Slash stake for misconduct (only authorized contracts)
     * @param provider Address of the provider
     * @param amount Amount to slash
     * @param jobId ID of the job
     * @param recipient Address to receive slashed funds
     */
    function slashStake(address provider, uint256 amount, bytes32 jobId, address recipient) external nonReentrant {
        require(authorizedContracts[msg.sender], "Not authorized");

        StakeInfo storage stakeInfo = stakes[provider];
        require(amount <= stakeInfo.lockedAmount, "Insufficient locked stake");

        stakeInfo.lockedAmount -= amount;
        stakeInfo.amount -= amount;

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");

        emit StakeSlashed(provider, amount, jobId);
    }

    /**
     * @notice Advanced risk-weighted slashing with context-aware penalties
     * @param provider Address of the provider to slash
     * @param baseAmount Base slash amount before multipliers (wei)
     * @param severity Violation severity score (0-100)
     * @param stakeAtRisk Amount of stake locked for this specific job (wei)
     * @param jobId ID of the job where violation occurred
     * @param recipient Address to receive slashed funds
     * @return finalSlashAmount The actual amount slashed after all calculations
     */
    function slashStakeAdvanced(
        address provider,
        uint256 baseAmount,
        uint256 severity,
        uint256 stakeAtRisk,
        bytes32 jobId,
        address recipient
    ) external nonReentrant returns (uint256 finalSlashAmount) {
        require(authorizedContracts[msg.sender], "Not authorized");
        require(severity <= 100, "Severity must be 0-100");

        StakeInfo storage stakeInfo = stakes[provider];

        // Get provider reputation (default to 500 if not registered)
        uint256 reputation = 500;
        if (address(reputationNFT) != address(0)) {
            try reputationNFT.getProviderReputation(provider) returns (
                ReputationNFT.ReputationData memory repData
            ) {
                reputation = repData.score;
            } catch {
                // Provider not registered in ReputationNFT, use default
                reputation = 500;
            }
        }

        // Calculate risk-weighted slash amount using advanced math
        finalSlashAmount = SlashingMath.calculateSlashAmount(
            baseAmount,
            severity,
            stakeInfo.violationCount,
            reputation,
            stakeAtRisk,
            stakeInfo.amount
        );

        // Ensure we don't slash more than locked amount
        require(finalSlashAmount <= stakeInfo.lockedAmount, "Insufficient locked stake");

        // Increment violation counter for repeat offender tracking
        stakeInfo.violationCount++;

        // Deduct from stake
        stakeInfo.lockedAmount -= finalSlashAmount;
        stakeInfo.amount -= finalSlashAmount;

        // Transfer slashed funds to recipient
        (bool success, ) = recipient.call{value: finalSlashAmount}("");
        require(success, "Transfer failed");

        emit StakeSlashedAdvanced(
            provider,
            baseAmount,
            finalSlashAmount,
            severity,
            stakeInfo.violationCount - 1, // Emit count before increment
            jobId
        );

        return finalSlashAmount;
    }

    /**
     * @notice Authorize a contract to lock/unlock/slash stakes
     * @param contractAddress Address of the contract
     * @param authorized Whether to authorize
     */
    function setAuthorizedContract(address contractAddress, bool authorized) external onlyOwner {
        authorizedContracts[contractAddress] = authorized;
        emit ContractAuthorized(contractAddress, authorized);
    }

    /**
     * @notice Update minimum stake requirements
     * @param _minDataProviderStake New minimum for data providers
     * @param _minComputeProviderStake New minimum for compute providers
     */
    function updateMinimumStakes(uint256 _minDataProviderStake, uint256 _minComputeProviderStake) external onlyOwner {
        minDataProviderStake = _minDataProviderStake;
        minComputeProviderStake = _minComputeProviderStake;
    }

    /**
     * @notice Set the ReputationNFT contract address for reputation-weighted slashing
     * @param _reputationNFT Address of the ReputationNFT contract
     */
    function setReputationNFT(address _reputationNFT) external onlyOwner {
        reputationNFT = ReputationNFT(_reputationNFT);
        emit ReputationNFTUpdated(_reputationNFT);
    }

    /**
     * @notice Get stake information for a provider
     * @param provider Address of the provider
     * @return StakeInfo struct
     */
    function getStakeInfo(address provider) external view returns (StakeInfo memory) {
        return stakes[provider];
    }

    /**
     * @notice Check if a provider has sufficient available stake
     * @param provider Address of the provider
     * @param amount Required amount
     * @return bool True if sufficient stake available
     */
    function hasSufficientStake(address provider, uint256 amount) external view returns (bool) {
        return stakes[provider].availableAmount >= amount;
    }
}
