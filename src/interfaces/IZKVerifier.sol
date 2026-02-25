// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IZKVerifier
 * @notice Interface for ZK proof verification (enables upgradability)
 * @dev Implementations should verify Groth16 proofs for training verification
 */
interface IZKVerifier {
    /**
     * @notice Verify a training proof
     * @param jobId The ID of the training job
     * @param proof The Groth16 proof (8 uint256 values: [a.x, a.y, b.x[0], b.x[1], b.y[0], b.y[1], c.x, c.y])
     * @param publicInputs The public inputs to the circuit
     * @return bool True if the proof is valid
     */
    function verifyTrainingProof(
        bytes32 jobId,
        uint256[8] calldata proof,
        uint256[] calldata publicInputs
    ) external returns (bool);

    /**
     * @notice Validate that public inputs match on-chain commitments
     * @param datasetCommitment Poseidon hash commitment of the dataset
     * @param modelCommitment Commitment of the trained model weights
     * @param metricsCommitment Commitment of the training metrics
     * @param publicInputs The public inputs from the proof
     * @return bool True if public inputs are valid and match commitments
     */
    function validatePublicInputs(
        bytes32 datasetCommitment,
        bytes32 modelCommitment,
        bytes32 metricsCommitment,
        uint256[] calldata publicInputs
    ) external pure returns (bool);

    /**
     * @notice Check if a proof has already been used (replay prevention)
     * @param proofHash Hash of the proof
     * @return bool True if proof has been used
     */
    function isProofUsed(bytes32 proofHash) external view returns (bool);
}
