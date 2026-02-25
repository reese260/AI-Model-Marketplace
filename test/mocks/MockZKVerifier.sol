// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/interfaces/IZKVerifier.sol";

/**
 * @title MockZKVerifier
 * @notice Mock implementation of ZK verifier for testing
 * @dev Allows configuring verification results for unit tests
 */
contract MockZKVerifier is IZKVerifier {
    // Configurable return value for verifyTrainingProof
    bool public shouldVerify = true;

    // Configurable return value for validatePublicInputs
    bool public shouldValidateInputs = true;

    // Track used proofs for replay prevention
    mapping(bytes32 => bool) public usedProofs;

    // Track verification calls for testing
    uint256 public verifyCallCount;
    uint256 public validateCallCount;

    // Last verification parameters (for test assertions)
    bytes32 public lastJobId;
    uint256[8] public lastProof;
    uint256[] public lastPublicInputs;
    bytes32 public lastDatasetCommitment;
    bytes32 public lastModelCommitment;
    bytes32 public lastMetricsCommitment;

    // Events for testing
    event MockVerifyTrainingProofCalled(bytes32 indexed jobId, bytes32 proofHash);
    event MockValidatePublicInputsCalled(bytes32 datasetCommitment, bytes32 modelCommitment, bytes32 metricsCommitment);

    /**
     * @notice Configure whether verification should succeed
     * @param _shouldVerify Whether to return true from verifyTrainingProof
     */
    function setShouldVerify(bool _shouldVerify) external {
        shouldVerify = _shouldVerify;
    }

    /**
     * @notice Configure whether input validation should succeed
     * @param _shouldValidate Whether to return true from validatePublicInputs
     */
    function setShouldValidateInputs(bool _shouldValidate) external {
        shouldValidateInputs = _shouldValidate;
    }

    /**
     * @notice Mark a proof as used (for testing replay prevention)
     * @param proofHash The proof hash to mark as used
     */
    function setProofUsed(bytes32 proofHash) external {
        usedProofs[proofHash] = true;
    }

    /**
     * @notice Reset the mock state
     */
    function reset() external {
        shouldVerify = true;
        shouldValidateInputs = true;
        verifyCallCount = 0;
        validateCallCount = 0;
        lastJobId = bytes32(0);
        delete lastPublicInputs;
    }

    /**
     * @notice Mock implementation of verifyTrainingProof
     */
    function verifyTrainingProof(
        bytes32 jobId,
        uint256[8] calldata proof,
        uint256[] calldata publicInputs
    ) external override returns (bool) {
        // Calculate proof hash
        bytes32 proofHash = keccak256(abi.encodePacked(proof, publicInputs));

        // Check for replay
        require(!usedProofs[proofHash], "Proof already used");

        // Store parameters for testing
        lastJobId = jobId;
        for (uint256 i = 0; i < 8; i++) {
            lastProof[i] = proof[i];
        }
        delete lastPublicInputs;
        for (uint256 i = 0; i < publicInputs.length; i++) {
            lastPublicInputs.push(publicInputs[i]);
        }

        verifyCallCount++;

        // Mark proof as used if verification succeeds
        if (shouldVerify) {
            usedProofs[proofHash] = true;
        }

        emit MockVerifyTrainingProofCalled(jobId, proofHash);

        return shouldVerify;
    }

    // Magic value to trigger validation failure (for testing)
    bytes32 constant MAGIC_FAIL_COMMITMENT = bytes32(uint256(0xDEAD));

    /**
     * @notice Mock implementation of validatePublicInputs
     * @dev Since this is pure, we can't read storage. Instead:
     *      - Use MAGIC_FAIL_COMMITMENT to trigger failure in tests
     *      - Otherwise perform actual validation
     */
    function validatePublicInputs(
        bytes32 datasetCommitment,
        bytes32 modelCommitment,
        bytes32 metricsCommitment,
        uint256[] calldata publicInputs
    ) external pure override returns (bool) {
        // Magic value to force failure in tests
        if (datasetCommitment == MAGIC_FAIL_COMMITMENT) {
            return false;
        }

        // Actual validation logic
        if (publicInputs.length < 3) {
            return false;
        }
        if (publicInputs[0] != uint256(datasetCommitment)) {
            return false;
        }
        if (publicInputs[1] != uint256(modelCommitment)) {
            return false;
        }
        if (publicInputs[2] != uint256(metricsCommitment)) {
            return false;
        }

        return true;
    }

    /**
     * @notice Check if a proof has been used
     */
    function isProofUsed(bytes32 proofHash) external view override returns (bool) {
        return usedProofs[proofHash];
    }

    /**
     * @notice Get the last public inputs (for test assertions)
     */
    function getLastPublicInputs() external view returns (uint256[] memory) {
        return lastPublicInputs;
    }

    /**
     * @notice Get the last proof (for test assertions)
     */
    function getLastProof() external view returns (uint256[8] memory) {
        return lastProof;
    }
}
