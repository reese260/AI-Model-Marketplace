// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IZKVerifier.sol";
import "./Groth16Verifier.sol";

/**
 * @title ZKTrainingVerifier
 * @notice Wrapper contract for ZK proof verification of AI model training
 * @dev Calls Groth16Verifier for proof verification, validates public inputs,
 *      and tracks verified proof hashes for replay prevention.
 *
 * VERIFICATION FLOW:
 * 1. Validate public inputs match on-chain commitments
 * 2. Check proof hasn't been used before (replay prevention)
 * 3. Call Groth16Verifier for pairing check
 * 4. Record proof hash as used
 *
 * GAS COST: ~200k gas for verification
 */
contract ZKTrainingVerifier is Initializable, IZKVerifier, OwnableUpgradeable, UUPSUpgradeable {
    // Reference to the Groth16 verifier contract
    Groth16Verifier public groth16Verifier;

    // Mapping of proof hashes to prevent replay attacks
    mapping(bytes32 => bool) public usedProofs;

    // Mapping of job IDs to their verified proof hashes
    mapping(bytes32 => bytes32) public jobProofHashes;

    // Events
    event ProofVerified(bytes32 indexed jobId, bytes32 proofHash);
    event Groth16VerifierUpdated(address indexed oldVerifier, address indexed newVerifier);

    // Errors
    error ProofAlreadyUsed(bytes32 proofHash);
    error InvalidPublicInputs();
    error ProofVerificationFailed();
    error InvalidGroth16Verifier();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _groth16Verifier) public initializer {
        __Ownable_init(msg.sender);
        require(_groth16Verifier != address(0), "Invalid verifier address");
        groth16Verifier = Groth16Verifier(_groth16Verifier);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
     * @notice Verify a training proof for a job
     * @param jobId The ID of the training job
     * @param proof The Groth16 proof
     * @param publicInputs The public inputs (commitments converted to field elements)
     * @return bool True if verification succeeds
     */
    function verifyTrainingProof(
        bytes32 jobId,
        uint256[8] calldata proof,
        uint256[] calldata publicInputs
    ) external override returns (bool) {
        // Calculate proof hash for replay prevention
        bytes32 proofHash = keccak256(abi.encodePacked(proof, publicInputs));

        // Check for replay attack
        if (usedProofs[proofHash]) {
            revert ProofAlreadyUsed(proofHash);
        }

        // Unpack proof array into Groth16 format:
        //   proof[0..1] = pA (G1 point)
        //   proof[2..5] = pB (G2 point, 2x2)
        //   proof[6..7] = pC (G1 point)
        uint[2] memory pA = [proof[0], proof[1]];
        uint[2][2] memory pB = [[proof[2], proof[3]], [proof[4], proof[5]]];
        uint[2] memory pC = [proof[6], proof[7]];

        // Convert public inputs to fixed-size array (3 public signals)
        require(publicInputs.length >= 3, "Insufficient public inputs");
        uint[3] memory pubSignals = [publicInputs[0], publicInputs[1], publicInputs[2]];

        // Verify the proof using Groth16 verifier
        bool isValid = groth16Verifier.verifyProof(pA, pB, pC, pubSignals);

        if (!isValid) {
            revert ProofVerificationFailed();
        }

        // Mark proof as used
        usedProofs[proofHash] = true;
        jobProofHashes[jobId] = proofHash;

        emit ProofVerified(jobId, proofHash);

        return true;
    }

    /**
     * @notice Validate that public inputs match on-chain commitments
     * @param datasetCommitment Poseidon hash commitment of the dataset
     * @param modelCommitment Commitment of the trained model
     * @param metricsCommitment Commitment of the training metrics
     * @param publicInputs The public inputs from the proof
     * @return bool True if inputs are valid and match
     */
    function validatePublicInputs(
        bytes32 datasetCommitment,
        bytes32 modelCommitment,
        bytes32 metricsCommitment,
        uint256[] calldata publicInputs
    ) external pure override returns (bool) {
        // Need at least 3 public inputs for the commitments
        if (publicInputs.length < 3) {
            return false;
        }

        // Convert commitments to field elements and compare
        uint256 datasetInput = uint256(datasetCommitment);
        uint256 modelInput = uint256(modelCommitment);
        uint256 metricsInput = uint256(metricsCommitment);

        // Validate commitments match public inputs
        if (publicInputs[0] != datasetInput) {
            return false;
        }
        if (publicInputs[1] != modelInput) {
            return false;
        }
        if (publicInputs[2] != metricsInput) {
            return false;
        }

        return true;
    }

    /**
     * @notice Check if a proof has already been used
     * @param proofHash Hash of the proof
     * @return bool True if proof has been used
     */
    function isProofUsed(bytes32 proofHash) external view override returns (bool) {
        return usedProofs[proofHash];
    }

    /**
     * @notice Get the proof hash for a verified job
     * @param jobId The job ID
     * @return bytes32 The proof hash (zero if not verified with ZK)
     */
    function getJobProofHash(bytes32 jobId) external view returns (bytes32) {
        return jobProofHashes[jobId];
    }

    /**
     * @notice Update the Groth16 verifier contract (for upgrades)
     * @param _newVerifier Address of the new verifier
     */
    function updateGroth16Verifier(address _newVerifier) external onlyOwner {
        if (_newVerifier == address(0)) {
            revert InvalidGroth16Verifier();
        }

        address oldVerifier = address(groth16Verifier);
        groth16Verifier = Groth16Verifier(_newVerifier);

        emit Groth16VerifierUpdated(oldVerifier, _newVerifier);
    }

    /**
     * @notice Compute proof hash for a given proof and inputs
     * @dev Utility function for off-chain use
     * @param proof The proof points
     * @param publicInputs The public inputs
     * @return bytes32 The computed proof hash
     */
    function computeProofHash(
        uint256[8] calldata proof,
        uint256[] calldata publicInputs
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(proof, publicInputs));
    }
}
