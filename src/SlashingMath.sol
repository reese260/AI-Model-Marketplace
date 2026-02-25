// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SD59x18, sd, intoUint256} from "@prb/math/SD59x18.sol";

/**
 * @title SlashingMath
 * @author AI Model Marketplace
 * @notice Advanced mathematical library for risk-weighted slashing using sigmoid functions
 *
 * @dev This library implements sophisticated slashing penalty calculations based on:
 *      - Sigmoid functions for smooth severity curves
 *      - Exponential repeat offender penalties
 *      - Reputation-weighted adjustments
 *      - Stake-proportional risk scaling
 *
 * MATHEMATICAL FOUNDATIONS:
 * ========================
 *
 * 1. SIGMOID SEVERITY FUNCTION:
 *    Purpose: Create smooth, non-linear severity curves with bounded output
 *    Formula: σ(x) = 1 / (1 + e^(-k(x - x₀)))
 *
 *    Where:
 *    - x = severity input (0-100 scale in our implementation)
 *    - k = steepness parameter (how quickly sigmoid transitions)
 *    - x₀ = inflection point (center of the S-curve)
 *    - e ≈ 2.71828 (Euler's number)
 *
 *    Properties:
 *    - Output range: (0, 1) - never exactly 0 or 1
 *    - S-shaped curve: slow start, rapid middle transition, slow end
 *    - Symmetric around inflection point x₀
 *    - Derivative maximum at x = x₀
 *
 *    In our implementation:
 *    - k = 0.1 (moderate steepness, smooth transitions)
 *    - x₀ = 50 (center point at mid-severity)
 *    - x range: 0-100 (severity scores)
 *
 *    Behavior:
 *    - Severity 0 → multiplier ≈ 0.007 (minimal penalty)
 *    - Severity 25 → multiplier ≈ 0.076 (light penalty)
 *    - Severity 50 → multiplier = 0.5 (half slash)
 *    - Severity 75 → multiplier ≈ 0.924 (heavy penalty)
 *    - Severity 100 → multiplier ≈ 0.993 (near-maximum)
 *
 *    Why sigmoid over linear?
 *    ✓ Graceful handling of edge cases (no zero or full slash extremes)
 *    ✓ More forgiving for minor infractions
 *    ✓ Escalates appropriately for serious violations
 *    ✓ Standard in ML/statistics for classification boundaries
 *    ✗ Linear: harsh jumps, no smoothing at boundaries
 *
 * 2. EXPONENTIAL REPEAT OFFENDER PENALTY:
 *    Purpose: Heavily penalize repeat violations
 *    Formula: multiplier = baseMultiplier * (1 + growthRate)^violationCount
 *
 *    Where:
 *    - baseMultiplier = 1.0 (starting point)
 *    - growthRate = 0.5 (50% increase per violation)
 *    - violationCount = number of previous violations
 *
 *    Progression:
 *    - 1st offense: 1.0x (100% of base penalty)
 *    - 2nd offense: 1.5x (150% of base penalty)
 *    - 3rd offense: 2.25x (225% of base penalty)
 *    - 4th offense: 3.375x (337.5% of base penalty)
 *    - 5th offense: 5.06x (506% of base penalty)
 *
 *    Capped at 5.0x to prevent excessive punishment
 *
 *    Why exponential vs linear?
 *    ✓ Strong deterrent for repeat offenses
 *    ✓ Protects network from persistent bad actors
 *    ✓ Compounds appropriately (worse behavior = worse penalty)
 *    ✗ Linear: insufficient deterrent, doesn't escalate enough
 *
 * 3. REPUTATION-WEIGHTED ADJUSTMENT:
 *    Purpose: Higher reputation providers face steeper penalties (more to lose)
 *    Formula: adjustment = 1 + (1000 - reputation) / 2000
 *
 *    Rationale: Providers with high reputation should know better
 *    - They've been trusted with more jobs
 *    - They have more market knowledge
 *    - Violation is more egregious from experienced provider
 *
 *    Examples:
 *    - Reputation 1000 (max): adjustment = 1.0 (standard penalty)
 *    - Reputation 500 (mid): adjustment = 1.25 (25% increase)
 *    - Reputation 0 (min): adjustment = 1.5 (50% increase)
 *
 *    Counter-intuitive but fair: New providers (low rep) get harsher penalty
 *    because they haven't earned trust yet. One violation is more damaging
 *    to their credibility than for established providers.
 *
 * 4. STAKE-PROPORTIONAL RISK SCALING:
 *    Purpose: Prevent whales from shrugging off penalties
 *    Formula: riskFactor = sqrt(stakeAtRisk / totalStake)
 *
 *    Why square root?
 *    - Linear scaling would over-penalize small risks
 *    - Sqrt provides diminishing penalty as stake ratio decreases
 *    - Standard in financial risk models (volatility scaling)
 *
 *    Examples:
 *    - 100% of stake at risk → riskFactor = 1.0 (full impact)
 *    - 25% of stake at risk → riskFactor = 0.5 (half impact)
 *    - 6.25% of stake at risk → riskFactor = 0.25 (quarter impact)
 *
 * COMPLETE SLASHING FORMULA:
 * =========================
 * finalSlash = baseAmount * σ(severity) * (1.5)^violations * repAdjustment * sqrt(stakeRatio)
 *
 * Where each component serves a specific purpose:
 * - baseAmount: Proposed slash by governance/oracle
 * - σ(severity): Smooth severity curve (0.007 to 0.993)
 * - (1.5)^violations: Exponential repeat offender penalty (1x to 5x)
 * - repAdjustment: Reputation-based weighting (1.0x to 1.5x)
 * - sqrt(stakeRatio): Risk-proportional scaling (0 to 1)
 *
 * WORKED EXAMPLE - MEDIUM SEVERITY, REPEAT OFFENDER:
 * - Base slash: 1 ETH
 * - Severity: 60 (moderate-high)
 * - Violations: 2 (third offense)
 * - Reputation: 700 (good standing)
 * - Stake at risk: 5 ETH, Total stake: 20 ETH
 *
 * Calculation:
 * 1. σ(60) ≈ 0.645 (from sigmoid)
 * 2. Repeat multiplier = 1.5² = 2.25
 * 3. Rep adjustment = 1 + (1000-700)/2000 = 1.15
 * 4. Risk factor = sqrt(5/20) = sqrt(0.25) = 0.5
 * 5. Final = 1 ETH * 0.645 * 2.25 * 1.15 * 0.5 ≈ 0.835 ETH
 *
 * Result: 0.835 ETH slashed (83.5% of proposed base)
 *
 * NUMERICAL PRECISION:
 * ===================
 * Uses PRBMath SD59x18 (signed 59.18-decimal fixed-point numbers)
 * - Critical for exponential and division operations
 * - Maintains precision through multiple multiplications
 * - Prevents rounding errors that could be exploited
 */
library SlashingMath {
    using {sd} for int256;

    /// @notice Sigmoid steepness parameter (k = 0.1)
    /// @dev Controls how quickly sigmoid transitions from 0 to 1
    ///      Higher k = steeper curve (more binary-like)
    ///      Lower k = gentler curve (more gradual)
    int256 constant SIGMOID_STEEPNESS = 0.1e18;

    /// @notice Sigmoid inflection point (x₀ = 50)
    /// @dev Center of S-curve where output = 0.5
    ///      This is the "medium severity" point
    int256 constant SIGMOID_INFLECTION = 50e18;

    /// @notice Growth rate for repeat offender penalty (50% increase per violation)
    /// @dev Exponential base: (1 + 0.5)^n = 1.5^n
    int256 constant REPEAT_OFFENDER_RATE = 0.5e18;

    /// @notice Maximum multiplier for repeat offenders (5x cap)
    /// @dev Prevents excessive penalties, even for many violations
    int256 constant MAX_REPEAT_MULTIPLIER = 5e18;

    /// @notice Maximum reputation score (1000)
    uint256 constant MAX_REPUTATION = 1000;

    /// @notice One in SD59x18 format
    int256 constant ONE = 1e18;

    /// @notice Two in SD59x18 format
    int256 constant TWO = 2e18;

    /**
     * @notice Calculates sigmoid severity multiplier
     * @dev Implements σ(x) = 1 / (1 + e^(-k(x - x₀)))
     *
     * SIGMOID FUNCTION DEEP DIVE:
     * The sigmoid (also called logistic function) is fundamental in:
     * - Machine learning (activation function in neural networks)
     * - Statistics (logistic regression)
     * - Economics (market saturation curves)
     * - Biology (population growth)
     *
     * DERIVATION:
     * σ(x) = 1 / (1 + e^(-k(x - x₀)))
     *
     * Step-by-step computation:
     * 1. Calculate offset: (x - x₀)
     *    - Centers the sigmoid around inflection point
     *    - Negative offsets → low output, Positive → high output
     *
     * 2. Scale by steepness: k * (x - x₀)
     *    - Stretches or compresses the S-curve
     *    - Our k=0.1 provides smooth, gradual transition
     *
     * 3. Negate: -k * (x - x₀)
     *    - Flips curve for proper orientation
     *    - Low severity → low penalty (not high)
     *
     * 4. Exponentiate: e^(-k(x - x₀))
     *    - Creates exponential decay component
     *    - PRBMath handles this with high precision
     *
     * 5. Add 1: 1 + e^(-k(x - x₀))
     *    - Shifts denominator, controls output range
     *
     * 6. Invert: 1 / (1 + e^(-k(x - x₀)))
     *    - Final sigmoid output
     *    - Always between 0 and 1
     *
     * PROPERTIES:
     * - Continuous and differentiable everywhere
     * - Monotonically increasing (always rising, never falling)
     * - Symmetric around inflection point
     * - Asymptotic to 0 and 1 (approaches but never reaches)
     *
     * CRITICAL POINTS:
     * - σ(0) ≈ 0.007 (practically zero, but not exactly)
     * - σ(50) = 0.5 (exactly half, at inflection)
     * - σ(100) ≈ 0.993 (practically one, but not exactly)
     *
     * WHY THIS MATTERS FOR SLASHING:
     * - Minor infractions get minor penalties (forgiveness)
     * - Major infractions get heavy penalties (deterrence)
     * - No absolute zero slash (always some consequence)
     * - No absolute full slash (always some mercy)
     * - Smooth gradients prevent gaming thresholds
     *
     * @param severity Violation severity score (0-100)
     *                 0 = trivial, 50 = moderate, 100 = critical
     * @return multiplier Sigmoid-adjusted severity (0 to 1 in SD59x18)
     */
    function calculateSeverityMultiplier(uint256 severity)
        internal
        pure
        returns (SD59x18 multiplier)
    {
        // Convert severity to SD59x18 fixed-point
        SD59x18 x = sd(int256(severity * 1e18));

        // Calculate (x - x₀): offset from inflection point
        SD59x18 offset = x.sub(sd(SIGMOID_INFLECTION));

        // Calculate k * (x - x₀): scaled offset
        SD59x18 scaledOffset = sd(SIGMOID_STEEPNESS).mul(offset);

        // Calculate -k * (x - x₀): negate for proper orientation
        SD59x18 negativeExponent = scaledOffset.mul(sd(-ONE));

        // Calculate e^(-k(x - x₀)): exponential component
        SD59x18 expTerm = negativeExponent.exp();

        // Calculate 1 + e^(-k(x - x₀)): denominator
        SD59x18 denominator = sd(ONE).add(expTerm);

        // Calculate σ(x) = 1 / (1 + e^(-k(x - x₀)))
        multiplier = sd(ONE).div(denominator);
    }

    /**
     * @notice Calculates repeat offender penalty multiplier
     * @dev Implements exponential growth: (1 + r)^n, capped at maximum
     *
     * EXPONENTIAL GROWTH THEORY:
     * General formula: A(t) = A₀ * (1 + r)^t
     * Where:
     * - A(t) = amount at time t (our penalty multiplier)
     * - A₀ = initial amount (1.0 in our case)
     * - r = growth rate (0.5 = 50%)
     * - t = time periods (violation count)
     *
     * COMPOUND GROWTH ANALOGY:
     * Similar to compound interest in finance:
     * - Bank: money grows exponentially with compound interest
     * - Slashing: penalty grows exponentially with violations
     *
     * MATHEMATICAL JUSTIFICATION:
     * Why exponential vs linear (1 + 0.5*n)?
     * - Linear: 1x, 1.5x, 2x, 2.5x, 3x (arithmetic progression)
     * - Exponential: 1x, 1.5x, 2.25x, 3.375x, 5.06x (geometric progression)
     *
     * Exponential advantages:
     * ✓ Stronger deterrent (penalty grows faster)
     * ✓ Compounds past mistakes (history matters)
     * ✓ Self-limiting with cap (prevents infinity)
     * ✓ Models real-world risk escalation
     *
     * CAP RATIONALE:
     * Maximum multiplier = 5.0x prevents:
     * - Excessive punishment for reformed providers
     * - Exploitative over-penalization
     * - Complete stake wipeout from single violation
     *
     * Reached after ~5-6 violations (1.5^5 ≈ 7.59 → capped to 5.0)
     *
     * EXAMPLE PROGRESSION:
     * Assume base slash = 0.5 ETH
     * - Violation 1: 0.5 * 1.0 = 0.5 ETH
     * - Violation 2: 0.5 * 1.5 = 0.75 ETH (+50%)
     * - Violation 3: 0.5 * 2.25 = 1.125 ETH (+50% of previous)
     * - Violation 4: 0.5 * 3.375 = 1.688 ETH
     * - Violation 5: 0.5 * 5.0 = 2.5 ETH (capped)
     * - Violation 6+: 0.5 * 5.0 = 2.5 ETH (remains capped)
     *
     * @param violationCount Number of previous violations by this provider
     * @return multiplier Exponential penalty multiplier (1.0x to 5.0x in SD59x18)
     */
    function calculateRepeatOffenderMultiplier(uint256 violationCount)
        internal
        pure
        returns (SD59x18 multiplier)
    {
        // No violations = no multiplier (1.0x)
        if (violationCount == 0) {
            return sd(ONE);
        }

        // Calculate base: (1 + rate) = 1.5
        SD59x18 base = sd(ONE).add(sd(REPEAT_OFFENDER_RATE));

        // Calculate exponent: (1.5)^violationCount
        // PRBMath pow() handles: base^exponent
        SD59x18 exponent = sd(int256(violationCount * 1e18));
        multiplier = base.pow(exponent);

        // Apply cap: max 5.0x multiplier
        if (multiplier.gt(sd(MAX_REPEAT_MULTIPLIER))) {
            multiplier = sd(MAX_REPEAT_MULTIPLIER);
        }
    }

    /**
     * @notice Calculates reputation-weighted adjustment factor
     * @dev Higher reputation → closer to 1.0x, Lower reputation → up to 1.5x
     *
     * REPUTATION PENALTY PHILOSOPHY:
     * Counter-intuitive design: Lower reputation = HIGHER penalty
     *
     * Traditional thinking: "Punish high-rep providers more (they should know better)"
     * Our approach: "Punish low-rep providers more (they haven't earned trust)"
     *
     * RATIONALE:
     * 1. Trust is earned: New providers must prove reliability
     * 2. One violation matters more with limited history
     * 3. Statistical significance: Few data points → higher variance
     * 4. Market protection: Prevents new bad actors from exploiting system
     *
     * FORMULA DERIVATION:
     * adjustment = 1 + (MAX_REPUTATION - currentReputation) / (2 * MAX_REPUTATION)
     *            = 1 + (1000 - rep) / 2000
     *
     * Range analysis:
     * - rep = 1000: adjustment = 1 + 0/2000 = 1.0 (minimum penalty)
     * - rep = 500: adjustment = 1 + 500/2000 = 1.25 (moderate increase)
     * - rep = 0: adjustment = 1 + 1000/2000 = 1.5 (maximum penalty)
     *
     * Division by 2000 (not 1000) ensures:
     * - Adjustment range: [1.0, 1.5] (50% swing)
     * - Not too harsh (avoids 2x penalty for new providers)
     * - Not too lenient (meaningful difference exists)
     *
     * EXAMPLE SCENARIOS:
     * Assume base slash = 1 ETH, severity = 50 (σ ≈ 0.5)
     *
     * Scenario A - Established provider (rep=900):
     * - Adjustment = 1 + 100/2000 = 1.05
     * - Slash = 1 * 0.5 * 1.05 = 0.525 ETH
     *
     * Scenario B - New provider (rep=200):
     * - Adjustment = 1 + 800/2000 = 1.4
     * - Slash = 1 * 0.5 * 1.4 = 0.7 ETH (+33% vs established)
     *
     * ALTERNATIVE APPROACHES REJECTED:
     * 1. Linear increase with reputation: Punishes success
     * 2. No reputation weighting: Ignores trust signals
     * 3. Exponential penalty: Too harsh on new entrants
     *
     * @param reputation Provider's current reputation score (0-1000)
     * @return adjustment Reputation-based multiplier (1.0x to 1.5x in SD59x18)
     */
    function calculateReputationAdjustment(uint256 reputation)
        internal
        pure
        returns (SD59x18 adjustment)
    {
        // Calculate reputation deficit: (MAX_REPUTATION - reputation)
        uint256 reputationDeficit = MAX_REPUTATION - reputation;

        // Convert to SD59x18
        SD59x18 deficit = sd(int256(reputationDeficit * 1e18));

        // Calculate adjustment: 1 + deficit / 2000
        // Division by 2 * MAX_REPUTATION = 2000
        SD59x18 divisor = sd(int256(2 * MAX_REPUTATION * 1e18));
        SD59x18 scaledDeficit = deficit.div(divisor);

        // Final adjustment
        adjustment = sd(ONE).add(scaledDeficit);
    }

    /**
     * @notice Calculates stake-proportional risk factor
     * @dev Uses square root scaling: sqrt(stakeAtRisk / totalStake)
     *
     * STAKE RISK SCALING THEORY:
     * Problem: Should 1 ETH slash mean the same to everyone?
     * - Provider A: 1 ETH slashed from 100 ETH stake (1% loss)
     * - Provider B: 1 ETH slashed from 2 ETH stake (50% loss)
     *
     * Fair answer: No. Impact should scale with proportion at risk.
     *
     * PROPORTIONAL RISK:
     * stakeRatio = stakeAtRisk / totalStake
     * - 1.0 = 100% of stake at risk (maximum exposure)
     * - 0.5 = 50% of stake at risk
     * - 0.1 = 10% of stake at risk (minimal exposure)
     *
     * WHY SQUARE ROOT?
     * Linear scaling (use ratio directly) is too harsh:
     * - 1% stake at risk → 1% impact (too small)
     * - 100% stake at risk → 100% impact (fair)
     *
     * Square root provides balanced scaling:
     * - 1% stake at risk → 10% impact (more reasonable)
     * - 25% stake at risk → 50% impact (moderate)
     * - 100% stake at risk → 100% impact (full)
     *
     * MATHEMATICAL PRECEDENT:
     * Square root scaling appears in:
     * - Financial volatility (std dev scales with sqrt(time))
     * - Sample size confidence (error ∝ 1/sqrt(n))
     * - Dimensionality reduction (preserves relative distances)
     * - Risk parity portfolios (equal risk contribution)
     *
     * FORMULA:
     * riskFactor = sqrt(stakeAtRisk / totalStake)
     *
     * EXAMPLE CALCULATIONS:
     * Total stake = 20 ETH
     *
     * Case 1 - Small job:
     * - Stake at risk: 1 ETH (5% of total)
     * - Risk factor = sqrt(1/20) = sqrt(0.05) ≈ 0.224
     * - Interpretation: 22.4% impact weighting
     *
     * Case 2 - Medium job:
     * - Stake at risk: 5 ETH (25% of total)
     * - Risk factor = sqrt(5/20) = sqrt(0.25) = 0.5
     * - Interpretation: 50% impact weighting
     *
     * Case 3 - Large job:
     * - Stake at risk: 20 ETH (100% of total)
     * - Risk factor = sqrt(20/20) = sqrt(1.0) = 1.0
     * - Interpretation: 100% impact weighting (full exposure)
     *
     * EDGE CASES:
     * - stakeAtRisk = 0: return 0 (no risk, no penalty impact)
     * - stakeAtRisk > totalStake: impossible (enforced by staking contract)
     * - totalStake = 0: should never occur (can't slash unstaked provider)
     *
     * @param stakeAtRisk Amount of stake locked for this job (wei)
     * @param totalStake Provider's total staked amount (wei)
     * @return riskFactor Sqrt-scaled risk proportion (0 to 1 in SD59x18)
     */
    function calculateStakeRiskFactor(uint256 stakeAtRisk, uint256 totalStake)
        internal
        pure
        returns (SD59x18 riskFactor)
    {
        // Edge case: no stake at risk
        if (stakeAtRisk == 0 || totalStake == 0) {
            return sd(0);
        }

        // Calculate stake ratio: stakeAtRisk / totalStake
        SD59x18 stakeRatio = sd(int256(stakeAtRisk)).div(sd(int256(totalStake)));

        // Apply square root scaling
        riskFactor = stakeRatio.sqrt();
    }

    /**
     * @notice Calculates comprehensive risk-weighted slashing amount
     * @dev Combines all factors: severity, repeat offenses, reputation, stake risk
     *
     * COMPLETE SLASHING FORMULA:
     * ============================
     * finalSlash = baseAmount × σ(severity) × (1.5)^violations
     *              × repAdjustment × sqrt(stakeRatio)
     *
     * COMPONENT BREAKDOWN:
     *
     * 1. baseAmount: Proposed slash by governance/oracle
     *    - Foundation for calculation
     *    - Typically based on job value or fixed amount
     *    - Example: 1 ETH for data quality violation
     *
     * 2. σ(severity): Sigmoid severity multiplier [0.007, 0.993]
     *    - Smooth curve from minor to critical
     *    - Prevents harsh binary thresholds
     *    - See calculateSeverityMultiplier() for details
     *
     * 3. (1.5)^violations: Exponential repeat offender penalty [1.0, 5.0]
     *    - Compounds for each previous violation
     *    - Strong deterrent for bad actors
     *    - See calculateRepeatOffenderMultiplier() for details
     *
     * 4. repAdjustment: Reputation-weighted factor [1.0, 1.5]
     *    - Higher penalty for untrusted providers
     *    - Protects marketplace from new bad actors
     *    - See calculateReputationAdjustment() for details
     *
     * 5. sqrt(stakeRatio): Stake-proportional risk [0, 1]
     *    - Scales with exposure level
     *    - Fair treatment across stake sizes
     *    - See calculateStakeRiskFactor() for details
     *
     * WORKED EXAMPLES:
     * ================
     *
     * EXAMPLE 1: First-time offender, minor violation
     * Parameters:
     * - baseAmount: 0.5 ETH
     * - severity: 20 (minor)
     * - violationCount: 0 (first offense)
     * - reputation: 800 (good standing)
     * - stakeAtRisk: 2 ETH, totalStake: 10 ETH
     *
     * Calculation:
     * - σ(20) ≈ 0.12
     * - repeat: 1.0 (first offense)
     * - repAdj: 1 + (1000-800)/2000 = 1.1
     * - riskFactor: sqrt(2/10) = sqrt(0.2) ≈ 0.447
     * - finalSlash = 0.5 × 0.12 × 1.0 × 1.1 × 0.447
     *              = 0.5 × 0.059 ≈ 0.0295 ETH
     *
     * Result: ~0.03 ETH slashed (6% of proposed base) - very lenient
     *
     * EXAMPLE 2: Repeat offender, moderate violation
     * Parameters:
     * - baseAmount: 1.0 ETH
     * - severity: 50 (moderate)
     * - violationCount: 2 (third offense)
     * - reputation: 600 (average)
     * - stakeAtRisk: 5 ETH, totalStake: 15 ETH
     *
     * Calculation:
     * - σ(50) = 0.5 (inflection point)
     * - repeat: 1.5² = 2.25
     * - repAdj: 1 + (1000-600)/2000 = 1.2
     * - riskFactor: sqrt(5/15) ≈ 0.577
     * - finalSlash = 1.0 × 0.5 × 2.25 × 1.2 × 0.577
     *              ≈ 0.778 ETH
     *
     * Result: ~0.78 ETH slashed (78% of base) - substantial penalty
     *
     * EXAMPLE 3: Serial offender, critical violation
     * Parameters:
     * - baseAmount: 2.0 ETH
     * - severity: 90 (critical)
     * - violationCount: 4 (fifth offense)
     * - reputation: 300 (poor)
     * - stakeAtRisk: 10 ETH, totalStake: 10 ETH (max risk)
     *
     * Calculation:
     * - σ(90) ≈ 0.982
     * - repeat: 1.5⁴ ≈ 5.0 (capped)
     * - repAdj: 1 + (1000-300)/2000 = 1.35
     * - riskFactor: sqrt(10/10) = 1.0
     * - finalSlash = 2.0 × 0.982 × 5.0 × 1.35 × 1.0
     *              ≈ 13.26 ETH
     *
     * Result: ~13.26 ETH slashed (663% of base!)
     * Note: Would be capped by available stake (10 ETH max)
     *
     * EXAMPLE 4: New provider, medium violation
     * Parameters:
     * - baseAmount: 0.8 ETH
     * - severity: 40 (medium-low)
     * - violationCount: 0 (first offense)
     * - reputation: 100 (new, untrusted)
     * - stakeAtRisk: 1 ETH, totalStake: 5 ETH
     *
     * Calculation:
     * - σ(40) ≈ 0.269
     * - repeat: 1.0 (first offense)
     * - repAdj: 1 + (1000-100)/2000 = 1.45
     * - riskFactor: sqrt(1/5) = sqrt(0.2) ≈ 0.447
     * - finalSlash = 0.8 × 0.269 × 1.0 × 1.45 × 0.447
     *              ≈ 0.14 ETH
     *
     * Result: ~0.14 ETH slashed (17.5% of base)
     * Higher than example 1 due to low reputation (untrusted)
     *
     * SYSTEM PROPERTIES:
     * ==================
     * ✓ Forgiveness: First-time minor offenses receive minimal penalty
     * ✓ Escalation: Repeat violations compound exponentially
     * ✓ Fairness: Stakes are slashed proportionally to risk exposure
     * ✓ Trust: Reputation influences penalty severity
     * ✓ Smoothness: No harsh threshold cliffs (continuous sigmoid)
     * ✓ Bounded: Penalties can't exceed available stake
     * ✓ Transparency: All factors are auditable on-chain
     *
     * GAME THEORY IMPLICATIONS:
     * =========================
     * 1. Optimal strategy: Maintain high reputation, avoid violations
     * 2. Cost of violations increases super-linearly (exponential)
     * 3. New providers must be extra careful (reputation penalty)
     * 4. Large stakes incentivize careful job selection (risk factor)
     * 5. System naturally filters out bad actors (compound penalties)
     *
     * @param baseAmount Proposed base slashing amount (wei)
     * @param severity Violation severity score (0-100)
     * @param violationCount Number of previous violations
     * @param reputation Provider's current reputation (0-1000)
     * @param stakeAtRisk Amount of stake locked for this job (wei)
     * @param totalStake Provider's total staked amount (wei)
     * @return slashAmount Final calculated slashing penalty (wei)
     */
    function calculateSlashAmount(
        uint256 baseAmount,
        uint256 severity,
        uint256 violationCount,
        uint256 reputation,
        uint256 stakeAtRisk,
        uint256 totalStake
    ) internal pure returns (uint256 slashAmount) {
        // Convert base amount to SD59x18
        SD59x18 base = sd(int256(baseAmount));

        // Calculate all multipliers
        SD59x18 severityMult = calculateSeverityMultiplier(severity);
        SD59x18 repeatMult = calculateRepeatOffenderMultiplier(violationCount);
        SD59x18 reputationAdj = calculateReputationAdjustment(reputation);
        SD59x18 riskFactor = calculateStakeRiskFactor(stakeAtRisk, totalStake);

        // Apply complete formula:
        // finalSlash = base × severity × repeat × reputation × risk
        SD59x18 result = base
            .mul(severityMult)
            .mul(repeatMult)
            .mul(reputationAdj)
            .mul(riskFactor);

        // Convert back to uint256
        slashAmount = uint256(result.intoUint256());

        // Ensure we don't slash more than available stake
        // (Though this should be enforced by caller as well)
        if (slashAmount > totalStake) {
            slashAmount = totalStake;
        }
    }
}
