// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title ModelTrainingEscrow
 * @notice Handles escrow payments for AI model training jobs
 * @dev Securely holds funds until training is verified, then distributes to providers
 */
contract ModelTrainingEscrow is Initializable, OwnableUpgradeable, ReentrancyGuard, UUPSUpgradeable {
    enum EscrowStatus {
        ACTIVE,      // Funds locked, training in progress
        COMPLETED,   // Training verified, ready for release
        RELEASED,    // Funds distributed to providers
        REFUNDED,    // Funds returned to requester
        DISPUTED     // Under dispute
    }

    struct EscrowDetails {
        bytes32 jobId;
        address requester;
        address dataProvider;
        address computeProvider;
        uint256 totalAmount;
        uint256 dataProviderShare;    // Percentage (e.g., 2000 = 20%)
        uint256 computeProviderShare; // Percentage (e.g., 7000 = 70%)
        uint256 platformFee;          // Percentage (e.g., 1000 = 10%)
        uint256 createdAt;
        EscrowStatus status;
        uint256 zkProofBonus;         // Extra bonus for compute provider if ZK proof used
    }

    // Platform fee percentage (basis points, e.g., 1000 = 10%)
    uint256 public platformFeePercent;

    // Platform fee recipient
    address public feeRecipient;

    // Mapping from job ID to escrow details
    mapping(bytes32 => EscrowDetails) public escrows;

    // Authorized contracts that can manage escrows
    mapping(address => bool) public authorizedManagers;

    // Pending withdrawals for pull-payment pattern
    mapping(address => uint256) public pendingWithdrawals;

    // Events
    event EscrowCreated(
        bytes32 indexed jobId,
        address indexed requester,
        uint256 amount,
        address dataProvider,
        address computeProvider
    );
    event EscrowCompleted(bytes32 indexed jobId);
    event EscrowReleased(
        bytes32 indexed jobId,
        uint256 dataProviderAmount,
        uint256 computeProviderAmount,
        uint256 platformFeeAmount
    );
    event EscrowReleasedWithZKBonus(
        bytes32 indexed jobId,
        uint256 dataProviderAmount,
        uint256 computeProviderAmount,
        uint256 platformFeeAmount,
        uint256 zkBonusAmount
    );
    event EscrowRefunded(bytes32 indexed jobId, uint256 amount);
    event EscrowDisputed(bytes32 indexed jobId);
    event WithdrawalReady(address indexed recipient, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _platformFeePercent, address _feeRecipient) public initializer {
        __Ownable_init(msg.sender);
        require(_platformFeePercent <= 2000, "Fee too high"); // Max 20%
        require(_feeRecipient != address(0), "Invalid fee recipient");
        platformFeePercent = _platformFeePercent;
        feeRecipient = _feeRecipient;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Create an escrow for a training job
     * @param jobId Unique identifier for the job
     * @param requester Address of the model requester
     * @param dataProvider Address of the data provider
     * @param computeProvider Address of the compute provider
     * @param dataProviderShare Percentage for data provider (basis points)
     * @param computeProviderShare Percentage for compute provider (basis points)
     */
    function createEscrow(
        bytes32 jobId,
        address requester,
        address dataProvider,
        address computeProvider,
        uint256 dataProviderShare,
        uint256 computeProviderShare
    ) external payable {
        _createEscrow(jobId, requester, dataProvider, computeProvider, dataProviderShare, computeProviderShare, 0);
    }

    /**
     * @notice Create an escrow for a training job with ZK bonus
     * @param jobId Unique identifier for the job
     * @param requester Address of the model requester
     * @param dataProvider Address of the data provider
     * @param computeProvider Address of the compute provider
     * @param dataProviderShare Percentage for data provider (basis points)
     * @param computeProviderShare Percentage for compute provider (basis points)
     * @param zkBonus Extra bonus for compute provider if ZK proof is submitted
     */
    function createEscrowWithZKBonus(
        bytes32 jobId,
        address requester,
        address dataProvider,
        address computeProvider,
        uint256 dataProviderShare,
        uint256 computeProviderShare,
        uint256 zkBonus
    ) external payable {
        _createEscrow(jobId, requester, dataProvider, computeProvider, dataProviderShare, computeProviderShare, zkBonus);
    }

    /**
     * @notice Internal function to create escrow
     */
    function _createEscrow(
        bytes32 jobId,
        address requester,
        address dataProvider,
        address computeProvider,
        uint256 dataProviderShare,
        uint256 computeProviderShare,
        uint256 zkBonus
    ) internal {
        require(authorizedManagers[msg.sender], "Not authorized");
        require(escrows[jobId].createdAt == 0, "Escrow already exists");
        require(msg.value > 0, "Must deposit funds");
        require(requester != address(0), "Invalid requester");
        require(dataProvider != address(0), "Invalid data provider");
        require(computeProvider != address(0), "Invalid compute provider");

        // Calculate base amount (total minus ZK bonus)
        uint256 baseAmount = msg.value - zkBonus;

        // Validate shares add up to 100% of base amount
        uint256 totalShares = dataProviderShare + computeProviderShare + platformFeePercent;
        require(totalShares == 10000, "Shares must equal 100%");

        escrows[jobId] = EscrowDetails({
            jobId: jobId,
            requester: requester,
            dataProvider: dataProvider,
            computeProvider: computeProvider,
            totalAmount: baseAmount,
            dataProviderShare: dataProviderShare,
            computeProviderShare: computeProviderShare,
            platformFee: platformFeePercent,
            createdAt: block.timestamp,
            status: EscrowStatus.ACTIVE,
            zkProofBonus: zkBonus
        });

        emit EscrowCreated(jobId, requester, msg.value, dataProvider, computeProvider);
    }

    /**
     * @notice Mark escrow as completed (called after verification)
     * @param jobId ID of the job
     */
    function completeEscrow(bytes32 jobId) external {
        require(authorizedManagers[msg.sender], "Not authorized");
        EscrowDetails storage escrowData = escrows[jobId];
        require(escrowData.status == EscrowStatus.ACTIVE, "Escrow not active");

        escrowData.status = EscrowStatus.COMPLETED;
        emit EscrowCompleted(jobId);
    }

    /**
     * @notice Release funds to providers (called after training verified)
     * @param jobId ID of the job
     * @param applyZKBonus Whether to apply the ZK bonus to compute provider
     */
    function releaseEscrow(bytes32 jobId, bool applyZKBonus) external nonReentrant {
        require(authorizedManagers[msg.sender], "Not authorized");
        EscrowDetails storage escrowData = escrows[jobId];
        require(escrowData.status == EscrowStatus.COMPLETED, "Escrow not completed");

        escrowData.status = EscrowStatus.RELEASED;

        uint256 totalAmount = escrowData.totalAmount;
        uint256 dataAmount = (totalAmount * escrowData.dataProviderShare) / 10000;
        uint256 computeAmount = (totalAmount * escrowData.computeProviderShare) / 10000;
        // Last share computed by subtraction to avoid rounding dust being locked
        uint256 feeAmount = totalAmount - dataAmount - computeAmount;

        // Determine ZK bonus
        uint256 zkBonus = applyZKBonus ? escrowData.zkProofBonus : 0;

        // Credit recipients via pull-payment pattern to prevent push-payment DoS
        pendingWithdrawals[escrowData.dataProvider] += dataAmount;
        emit WithdrawalReady(escrowData.dataProvider, dataAmount);

        uint256 computeTotal = computeAmount + zkBonus;
        pendingWithdrawals[escrowData.computeProvider] += computeTotal;
        emit WithdrawalReady(escrowData.computeProvider, computeTotal);

        pendingWithdrawals[feeRecipient] += feeAmount;
        emit WithdrawalReady(feeRecipient, feeAmount);

        // Refund unused ZK bonus to requester if not applied
        if (!applyZKBonus && escrowData.zkProofBonus > 0) {
            pendingWithdrawals[escrowData.requester] += escrowData.zkProofBonus;
            emit WithdrawalReady(escrowData.requester, escrowData.zkProofBonus);
        }

        if (zkBonus > 0) {
            emit EscrowReleasedWithZKBonus(jobId, dataAmount, computeAmount, feeAmount, zkBonus);
        } else {
            emit EscrowReleased(jobId, dataAmount, computeAmount, feeAmount);
        }
    }

    /**
     * @notice Refund escrow to requester (if training fails/rejected)
     * @param jobId ID of the job
     */
    function refundEscrow(bytes32 jobId) external nonReentrant {
        require(authorizedManagers[msg.sender], "Not authorized");
        EscrowDetails storage escrowData = escrows[jobId];
        require(
            escrowData.status == EscrowStatus.ACTIVE || escrowData.status == EscrowStatus.DISPUTED,
            "Cannot refund"
        );

        escrowData.status = EscrowStatus.REFUNDED;

        uint256 refundAmount = escrowData.totalAmount + escrowData.zkProofBonus;
        (bool success, ) = escrowData.requester.call{value: refundAmount}("");
        require(success, "Refund failed");

        emit EscrowRefunded(jobId, refundAmount);
    }

    /**
     * @notice Withdraw funds credited to the caller via the pull-payment pattern
     */
    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        pendingWithdrawals[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @notice Mark escrow as disputed
     * @param jobId ID of the job
     */
    function disputeEscrow(bytes32 jobId) external {
        require(authorizedManagers[msg.sender], "Not authorized");
        EscrowDetails storage escrowData = escrows[jobId];
        require(escrowData.status == EscrowStatus.ACTIVE, "Escrow not active");

        escrowData.status = EscrowStatus.DISPUTED;
        emit EscrowDisputed(jobId);
    }

    /**
     * @notice Authorize a contract to manage escrows
     * @param manager Address to authorize
     * @param authorized Whether to authorize
     */
    function setAuthorizedManager(address manager, bool authorized) external onlyOwner {
        authorizedManagers[manager] = authorized;
    }

    /**
     * @notice Update platform fee percentage
     * @param newFeePercent New fee percentage (basis points)
     */
    function updatePlatformFee(uint256 newFeePercent) external onlyOwner {
        require(newFeePercent <= 2000, "Fee too high"); // Max 20%
        platformFeePercent = newFeePercent;
    }

    /**
     * @notice Update fee recipient address
     * @param newRecipient New fee recipient
     */
    function updateFeeRecipient(address newRecipient) external onlyOwner {
        require(newRecipient != address(0), "Invalid address");
        feeRecipient = newRecipient;
    }

    /**
     * @notice Get escrow details
     * @param jobId ID of the job
     * @return EscrowDetails struct
     */
    function getEscrow(bytes32 jobId) external view returns (EscrowDetails memory) {
        return escrows[jobId];
    }

    /**
     * @notice Get escrow status
     * @param jobId ID of the job
     * @return EscrowStatus Current status
     */
    function getEscrowStatus(bytes32 jobId) external view returns (EscrowStatus) {
        return escrows[jobId].status;
    }
}
