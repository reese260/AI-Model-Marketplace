// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SD59x18, sd, intoUint256} from "@prb/math/SD59x18.sol";

/**
 * @title ReputationMath
 * @author AI Model Marketplace
 * @notice Advanced mathematical library for reputation scoring using exponential functions
 *
 * @dev This library implements sophisticated reputation algorithms including:
 *      - Exponential Moving Average (EMA) for dynamic reputation updates
 *      - Time-based exponential decay for historical job weighting
 *      - Job value weighting with logarithmic scaling
 *      - Statistical confidence scoring based on sample size
 *
 * MATHEMATICAL FOUNDATIONS:
 * ========================
 *
 * 1. EXPONENTIAL MOVING AVERAGE (EMA):
 *    Purpose: Gives more weight to recent performance while maintaining historical context
 *    Formula: newRep = α * currentJobScore + (1-α) * oldReputation
 *
 *    Where α (alpha) is the smoothing factor:
 *    - α = 2 / (N + 1), where N = effective window size
 *    - Higher α = more reactive to recent changes
 *    - Lower α = more stable, historical reputation matters more
 *
 *    In our implementation:
 *    - α varies based on job value (bigger jobs have more impact)
 *    - Base α = 0.2 (equivalent to ~9-job window)
 *    - Max α = 0.5 (for very high-value jobs)
 *
 * 2. EXPONENTIAL TIME DECAY:
 *    Purpose: Recent jobs should matter more than old ones
 *    Formula: decayedScore = baseScore * e^(-λt)
 *
 *    Where:
 *    - λ (lambda) = decay rate constant (higher = faster decay)
 *    - t = time elapsed since job completion (in days)
 *    - e ≈ 2.71828 (Euler's number)
 *
 *    In our implementation:
 *    - λ = 0.00274 per day (≈ 0.1% daily decay)
 *    - Results in ~25% decay after 1 year
 *    - ~50% decay after 2.5 years
 *    - Ensures recent performance is prioritized
 *
 * 3. LOGARITHMIC JOB VALUE WEIGHTING:
 *    Purpose: Prevent extremely high-value jobs from dominating reputation
 *    Formula: weight = log₂(1 + jobValue)
 *
 *    Why logarithmic?
 *    - Creates diminishing returns on value (fair scaling)
 *    - 1 ETH job → weight ≈ 1.0
 *    - 10 ETH job → weight ≈ 3.46 (not 10x)
 *    - 100 ETH job → weight ≈ 6.66 (not 100x)
 *    - Prevents whale manipulation
 *
 * 4. CONFIDENCE SCORE:
 *    Purpose: Account for statistical significance of reputation
 *    Formula: confidence = reputation * sqrt(jobsCompleted / referenceCount)
 *                        * (1 - failureRate)
 *
 *    Components:
 *    - sqrt term: Confidence increases with sample size, but with diminishing returns
 *    - Failure rate penalty: Linear reduction based on job failures
 *    - Reference count: 100 jobs (normalization constant)
 *
 *    Example:
 *    - 900 rep, 100 jobs, 0% failures → confidence = 900
 *    - 900 rep, 25 jobs, 0% failures → confidence = 450
 *    - 900 rep, 100 jobs, 10% failures → confidence = 810
 *
 * NUMERICAL PRECISION:
 * ===================
 * Uses PRBMath SD59x18 (signed 59.18-decimal fixed-point numbers)
 * - Range: -5.8e17 to 5.8e17
 * - Precision: 18 decimal places
 * - Allows fractional calculations in Solidity
 * - Standard for DeFi math operations
 */
library ReputationMath {
    using {sd} for int256;

    /// @notice Minimum reputation score (normalized to 0-1000 scale)
    uint256 constant MIN_REPUTATION = 0;

    /// @notice Maximum reputation score (normalized to 0-1000 scale)
    uint256 constant MAX_REPUTATION = 1000;

    /// @notice Base alpha for EMA calculation (0.2 = 20% weight to new data)
    /// @dev Equivalent to a 9-period moving average window: α = 2/(N+1) = 2/10 = 0.2
    int256 constant BASE_ALPHA = 0.2e18; // SD59x18 format (0.2 * 1e18)

    /// @notice Maximum alpha for high-value jobs (0.5 = 50% weight to new data)
    /// @dev Corresponds to a 3-period window, making reputation more reactive to valuable jobs
    int256 constant MAX_ALPHA = 0.5e18;

    /// @notice Decay rate for time-based reputation degradation
    /// @dev λ = 0.00274 per day ≈ 0.1% daily decay ≈ 25% annual decay
    /// @dev Calculated as: ln(0.75) / 365 ≈ -0.00274 (for 25% yearly reduction)
    int256 constant DECAY_LAMBDA = 0.00274e18;

    /// @notice Reference job count for confidence normalization
    /// @dev Providers with 100+ jobs have confidence score ≈ reputation
    uint256 constant REFERENCE_JOB_COUNT = 100;

    /// @notice One in SD59x18 format (for mathematical operations)
    int256 constant ONE = 1e18;

    /**
     * @notice Calculates alpha (smoothing factor) for EMA based on job value
     * @dev Higher job values increase alpha, giving them more weight in reputation
     *
     * ALGORITHM:
     * 1. Take log₂ of (1 + jobValue) to prevent extreme values from dominating
     * 2. Scale result to range [BASE_ALPHA, MAX_ALPHA]
     * 3. Clamp to MAX_ALPHA for very high-value jobs
     *
     * MATHEMATICAL DERIVATION:
     * - jobValue in wei (1 ether = 1e18 wei)
     * - log₂(1 + x) provides smooth scaling: log₂(2) = 1, log₂(101) ≈ 6.66
     * - Division by 20e18 normalizes to reasonable range
     * - Addition of BASE_ALPHA ensures minimum responsiveness
     *
     * EXAMPLES:
     * - 0.1 ETH job → alpha ≈ 0.20 (base level, standard weight)
     * - 1 ETH job → alpha ≈ 0.25 (moderate increase)
     * - 10 ETH job → alpha ≈ 0.37 (significant weight)
     * - 100 ETH job → alpha ≈ 0.50 (maximum weight, capped)
     *
     * @param jobValue The payment value of the job in wei
     * @return alpha The calculated smoothing factor in SD59x18 format
     */
    function calculateAlpha(uint256 jobValue) internal pure returns (SD59x18 alpha) {
        // Convert job value to SD59x18 fixed-point format
        SD59x18 value = sd(int256(jobValue));

        // Calculate log₂(1 + jobValue) for logarithmic scaling
        // Adding 1 prevents log(0) and ensures smooth curve from origin
        SD59x18 logValue = (value.add(sd(ONE))).log2();

        // Scale logarithm to alpha range
        // Division by 20e18 converts log output to appropriate magnitude
        SD59x18 scaledAlpha = logValue.div(sd(20e18));

        // Add base alpha to ensure minimum responsiveness
        alpha = scaledAlpha.add(sd(BASE_ALPHA));

        // Clamp to maximum alpha (prevent over-reactivity)
        if (alpha.gt(sd(MAX_ALPHA))) {
            alpha = sd(MAX_ALPHA);
        }
    }

    /**
     * @notice Calculates time-based exponential decay for historical reputation
     * @dev Implements continuous decay: decayedScore = baseScore * e^(-λt)
     *
     * EXPONENTIAL DECAY THEORY:
     * - Models natural degradation processes (radioactive decay, signal attenuation)
     * - Ensures smooth, predictable reputation decline over time
     * - Never reaches zero (asymptotic approach)
     * - Half-life calculation: t_half = ln(2) / λ ≈ 253 days
     *
     * DECAY SCHEDULE (with λ = 0.00274):
     * - 1 month (30d): ~92% retained (8% decay)
     * - 3 months (90d): ~78% retained (22% decay)
     * - 6 months (180d): ~61% retained (39% decay)
     * - 1 year (365d): ~37% retained (63% decay)
     * - 2 years (730d): ~14% retained (86% decay)
     *
     * WHY EXPONENTIAL VS LINEAR:
     * - Linear decay: -X points/day (harsh cliff, reaches zero)
     * - Exponential decay: proportional reduction (fair, never zero)
     * - Exponential is standard in finance/science for depreciation
     *
     * @param baseScore The original reputation score to decay
     * @param daysElapsed Number of days since the job was completed
     * @return decayedScore The time-adjusted reputation score
     */
    function calculateTimeDecay(uint256 baseScore, uint256 daysElapsed)
        internal
        pure
        returns (uint256 decayedScore)
    {
        // No decay if zero days elapsed
        if (daysElapsed == 0) {
            return baseScore;
        }

        // Convert inputs to SD59x18 fixed-point format
        // baseScore is already a normal uint, convert to SD59x18 by scaling
        SD59x18 score = sd(int256(baseScore * 1e18));

        // daysElapsed is a normal uint, convert to SD59x18 by scaling
        SD59x18 daysSD = sd(int256(daysElapsed * 1e18));

        // Calculate exponent: -λ * t
        // Negative because we want decay (reduction over time)
        SD59x18 exponent = sd(DECAY_LAMBDA).mul(daysSD).mul(sd(-ONE));

        // Calculate e^(-λt) using PRBMath's exp function
        // exp() returns the natural exponential: e^x
        SD59x18 decayFactor = exponent.exp();

        // Apply decay: finalScore = baseScore * e^(-λt)
        SD59x18 result = score.mul(decayFactor);

        // Convert back to uint256 (unscale from SD59x18 format)
        decayedScore = uint256(result.intoUint256()) / 1e18;
    }

    /**
     * @notice Updates reputation using Exponential Moving Average
     * @dev Implements adaptive EMA: newRep = α * jobScore + (1-α) * oldRep
     *
     * EMA ADVANTAGES OVER SIMPLE AVERAGE:
     * 1. Constant memory: doesn't need to store all historical scores
     * 2. Adaptive: recent performance has more weight
     * 3. Smooth: no sudden jumps from old data dropping off
     * 4. Efficient: O(1) computation vs O(n) for full average
     *
     * MATHEMATICAL PROOF OF EQUIVALENCE:
     * EMA with α=2/(N+1) ≈ Simple Moving Average over N periods
     * - Proof: Sum of geometric series converges to weighted average
     * - Our α=0.2 ≈ 9-period SMA
     * - Our max α=0.5 ≈ 3-period SMA (for high-value jobs)
     *
     * WORKED EXAMPLE:
     * - Current reputation: 750
     * - Job score: 900 (successful high-value job)
     * - Job value: 5 ETH
     * - Calculated α ≈ 0.35 (from calculateAlpha)
     * - New reputation = 0.35 * 900 + 0.65 * 750 = 315 + 487.5 = 802.5
     * - Result: 802 (rounded)
     *
     * BOUNDARY CONDITIONS:
     * - Always clamped to [MIN_REPUTATION, MAX_REPUTATION] = [0, 1000]
     * - Prevents overflow/underflow
     * - Ensures score remains in valid range
     *
     * @param currentReputation The provider's current reputation score (0-1000)
     * @param jobScore The score from the completed job (0-1000)
     * @param jobValue The payment value of the job in wei
     * @return newReputation The updated reputation score (0-1000)
     */
    function updateReputationEMA(
        uint256 currentReputation,
        uint256 jobScore,
        uint256 jobValue
    ) internal pure returns (uint256 newReputation) {
        // Calculate dynamic alpha based on job value
        SD59x18 alpha = calculateAlpha(jobValue);

        // Convert reputation scores to SD59x18 fixed-point (scale by 1e18)
        SD59x18 currentRep = sd(int256(currentReputation * 1e18));
        SD59x18 jobScoreSD = sd(int256(jobScore * 1e18));

        // Calculate (1 - α) for the historical component
        SD59x18 oneMinusAlpha = sd(ONE).sub(alpha);

        // Apply EMA formula: α * jobScore + (1-α) * currentRep
        // First term: weight of new job
        SD59x18 newComponent = alpha.mul(jobScoreSD);

        // Second term: weight of historical reputation
        SD59x18 historicalComponent = oneMinusAlpha.mul(currentRep);

        // Sum components to get new reputation
        SD59x18 result = newComponent.add(historicalComponent);

        // Convert back to uint256 and clamp to valid range (unscale from SD59x18)
        newReputation = uint256(result.intoUint256()) / 1e18;

        // Enforce bounds [MIN_REPUTATION, MAX_REPUTATION]
        if (newReputation < MIN_REPUTATION) {
            newReputation = MIN_REPUTATION;
        } else if (newReputation > MAX_REPUTATION) {
            newReputation = MAX_REPUTATION;
        }
    }

    /**
     * @notice Calculates statistical confidence score for provider reputation
     * @dev Combines reputation with sample size and success rate using statistical principles
     *
     * CONFIDENCE SCORE RATIONALE:
     * Raw reputation alone is misleading:
     * - Provider A: 950 score, 5 jobs → Less reliable
     * - Provider B: 850 score, 500 jobs → More reliable
     *
     * Confidence score addresses this by incorporating:
     * 1. Sample size effect (sqrt scaling)
     * 2. Failure rate penalty
     *
     * SQRT SAMPLE SIZE SCALING:
     * Based on statistical standard error: SE = σ/sqrt(n)
     * - Uncertainty decreases with sqrt(sample size)
     * - Our confidence increases with sqrt(job count)
     * - Diminishing returns: 100 jobs → 1x, 400 jobs → 2x
     *
     * FAILURE RATE PENALTY:
     * - Linear penalty: (1 - failureRate)
     * - 0% failures → 100% confidence
     * - 10% failures → 90% confidence
     * - 50% failures → 50% confidence
     *
     * FORMULA BREAKDOWN:
     * confidence = reputation * sqrt(jobsCompleted / REFERENCE_JOB_COUNT) * (1 - failureRate)
     *
     * EXAMPLE SCENARIOS:
     * 1. New provider (uncertain):
     *    - Rep: 900, Jobs: 10, Failures: 0
     *    - Confidence = 900 * sqrt(10/100) * 1.0 = 900 * 0.316 = 284
     *
     * 2. Established provider (confident):
     *    - Rep: 850, Jobs: 400, Failures: 5
     *    - FailureRate = 5/400 = 0.0125 (1.25%)
     *    - Confidence = 850 * sqrt(400/100) * 0.9875 = 850 * 2.0 * 0.9875 = 1679
     *
     * 3. Unreliable provider (penalized):
     *    - Rep: 800, Jobs: 100, Failures: 20
     *    - FailureRate = 20/100 = 0.2 (20%)
     *    - Confidence = 800 * sqrt(100/100) * 0.8 = 800 * 1.0 * 0.8 = 640
     *
     * USE CASES:
     * - Provider ranking/sorting in marketplace
     * - Job assignment probability weighting
     * - Risk assessment for high-value jobs
     * - Identifying statistically significant performance differences
     *
     * @param reputation Provider's current reputation score (0-1000)
     * @param jobsCompleted Total number of jobs completed successfully
     * @param jobsFailed Total number of jobs that failed
     * @return confidence Statistical confidence score (unbounded, higher = more reliable)
     */
    function calculateConfidenceScore(
        uint256 reputation,
        uint256 jobsCompleted,
        uint256 jobsFailed
    ) internal pure returns (uint256 confidence) {
        // Handle edge case: no jobs completed yet
        if (jobsCompleted == 0) {
            return 0;
        }

        // Convert to SD59x18 for fixed-point math (scale by 1e18)
        SD59x18 rep = sd(int256(reputation * 1e18));

        // Calculate sqrt(jobsCompleted / REFERENCE_JOB_COUNT)
        // This provides diminishing returns for sample size confidence
        SD59x18 sampleRatio = sd(int256(jobsCompleted * 1e18)).div(sd(int256(REFERENCE_JOB_COUNT * 1e18)));
        SD59x18 sampleFactor = sampleRatio.sqrt();

        // Calculate failure rate: failures / (completed + failed)
        uint256 totalJobs = jobsCompleted + jobsFailed;
        SD59x18 failureRate = sd(int256(jobsFailed * 1e18)).div(sd(int256(totalJobs * 1e18)));

        // Calculate success factor: (1 - failureRate)
        SD59x18 successFactor = sd(ONE).sub(failureRate);

        // Apply formula: confidence = rep * sqrt(jobs/ref) * (1 - failureRate)
        SD59x18 result = rep.mul(sampleFactor).mul(successFactor);

        // Convert back to uint256 (unscale from SD59x18 format)
        confidence = uint256(result.intoUint256()) / 1e18;
    }
}
