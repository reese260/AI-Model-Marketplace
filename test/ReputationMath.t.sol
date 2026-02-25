// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ReputationMath.sol";

contract ReputationMathTest is Test {
    /**
     * TEST SUITE: Alpha Calculation
     * Tests the dynamic alpha calculation based on job value
     */

    function testAlphaCalculation_SmallJob() public pure {
        // 0.1 ETH job should give base alpha (~0.2)
        uint256 jobValue = 0.1 ether;
        SD59x18 alpha = ReputationMath.calculateAlpha(jobValue);

        // Alpha should be close to BASE_ALPHA (0.2e18)
        assertGe(alpha.unwrap(), 0.19e18, "Alpha too low for small job");
        assertLe(alpha.unwrap(), 0.25e18, "Alpha too high for small job");
    }

    function testAlphaCalculation_MediumJob() public pure {
        // 1 ETH job should give moderate alpha
        uint256 jobValue = 1 ether;
        SD59x18 alpha = ReputationMath.calculateAlpha(jobValue);

        assertGe(alpha.unwrap(), 0.2e18, "Alpha too low for medium job");
        assertLe(alpha.unwrap(), 0.35e18, "Alpha too high for medium job");
    }

    function testAlphaCalculation_LargeJob() public pure {
        // 10 ETH job should give higher alpha
        uint256 jobValue = 10 ether;
        SD59x18 alpha = ReputationMath.calculateAlpha(jobValue);

        assertGe(alpha.unwrap(), 0.3e18, "Alpha too low for large job");
        assertLe(alpha.unwrap(), 0.45e18, "Alpha too high for large job");
    }

    function testAlphaCalculation_MaxCap() public pure {
        // Very large job should cap at MAX_ALPHA (0.5)
        uint256 jobValue = 100 ether;
        SD59x18 alpha = ReputationMath.calculateAlpha(jobValue);

        // Should be capped at or very close to 0.5
        assertEq(alpha.unwrap(), 0.5e18, "Alpha not capped at maximum");
    }

    function testAlphaCalculation_ZeroValue() public pure {
        // Zero value job should give base alpha
        uint256 jobValue = 0;
        SD59x18 alpha = ReputationMath.calculateAlpha(jobValue);

        assertGe(alpha.unwrap(), 0.15e18, "Alpha too low for zero value");
        assertLe(alpha.unwrap(), 0.25e18, "Alpha too high for zero value");
    }

    /**
     * TEST SUITE: Time Decay
     * Tests exponential decay over time
     */

    function testTimeDecay_NoTime() public pure {
        // No time passed should return same score
        uint256 baseScore = 750;
        uint256 daysElapsed = 0;

        uint256 decayedScore = ReputationMath.calculateTimeDecay(baseScore, daysElapsed);

        assertEq(decayedScore, baseScore, "Score should not decay with 0 days");
    }

    function testTimeDecay_OneDay() public pure {
        // 1 day should decay very slightly
        uint256 baseScore = 1000;
        uint256 daysElapsed = 1;

        uint256 decayedScore = ReputationMath.calculateTimeDecay(baseScore, daysElapsed);

        // Should lose ~0.274% (from λ = 0.00274)
        assertGe(decayedScore, 997, "Decay too aggressive for 1 day");
        assertLe(decayedScore, 1000, "Score increased instead of decayed");
    }

    function testTimeDecay_OneMonth() public pure {
        // 30 days should decay ~8%
        uint256 baseScore = 1000;
        uint256 daysElapsed = 30;

        uint256 decayedScore = ReputationMath.calculateTimeDecay(baseScore, daysElapsed);

        // Should retain ~92% (1000 * e^(-0.00274*30) ≈ 920)
        assertGe(decayedScore, 910, "Decay too aggressive for 30 days");
        assertLe(decayedScore, 930, "Decay too lenient for 30 days");
    }

    function testTimeDecay_ThreeMonths() public pure {
        // 90 days should decay ~22%
        uint256 baseScore = 1000;
        uint256 daysElapsed = 90;

        uint256 decayedScore = ReputationMath.calculateTimeDecay(baseScore, daysElapsed);

        // Should retain ~78% (1000 * e^(-0.00274*90) ≈ 780)
        assertGe(decayedScore, 770, "Decay too aggressive for 90 days");
        assertLe(decayedScore, 790, "Decay too lenient for 90 days");
    }

    function testTimeDecay_OneYear() public pure {
        // 365 days should decay ~63%
        uint256 baseScore = 1000;
        uint256 daysElapsed = 365;

        uint256 decayedScore = ReputationMath.calculateTimeDecay(baseScore, daysElapsed);

        // Should retain ~37% (1000 * e^(-0.00274*365) ≈ 370)
        assertGe(decayedScore, 360, "Decay too aggressive for 1 year");
        assertLe(decayedScore, 380, "Decay too lenient for 1 year");
    }

    function testTimeDecay_ZeroScore() public pure {
        // Zero score should remain zero
        uint256 baseScore = 0;
        uint256 daysElapsed = 365;

        uint256 decayedScore = ReputationMath.calculateTimeDecay(baseScore, daysElapsed);

        assertEq(decayedScore, 0, "Zero score should remain zero");
    }

    /**
     * TEST SUITE: Exponential Moving Average (EMA)
     * Tests reputation updates using EMA
     */

    function testEMA_SuccessfulJob_SmallValue() public pure {
        // Current rep: 500, Success (900), small job (0.1 ETH)
        uint256 currentRep = 500;
        uint256 jobScore = 900;
        uint256 jobValue = 0.1 ether;

        uint256 newRep = ReputationMath.updateReputationEMA(currentRep, jobScore, jobValue);

        // With low alpha (~0.2), new rep should be closer to old rep
        // newRep ≈ 0.2*900 + 0.8*500 = 180 + 400 = 580
        assertGe(newRep, 560, "Reputation increase too low");
        assertLe(newRep, 600, "Reputation increase too high");
    }

    function testEMA_SuccessfulJob_LargeValue() public pure {
        // Current rep: 500, Success (900), large job (10 ETH)
        uint256 currentRep = 500;
        uint256 jobScore = 900;
        uint256 jobValue = 10 ether;

        uint256 newRep = ReputationMath.updateReputationEMA(currentRep, jobScore, jobValue);

        // With high alpha (~0.37), new rep should move more toward job score
        // newRep ≈ 0.37*900 + 0.63*500 = 333 + 315 = 648
        assertGe(newRep, 630, "Reputation increase too low for large job");
        assertLe(newRep, 670, "Reputation increase too high for large job");
    }

    function testEMA_FailedJob() public pure {
        // Current rep: 750, Failure (100), medium job (1 ETH)
        uint256 currentRep = 750;
        uint256 jobScore = 100;
        uint256 jobValue = 1 ether;

        uint256 newRep = ReputationMath.updateReputationEMA(currentRep, jobScore, jobValue);

        // Rep should decrease
        // newRep ≈ 0.25*100 + 0.75*750 = 25 + 562.5 = 587.5
        assertGe(newRep, 570, "Reputation decrease too aggressive");
        assertLe(newRep, 610, "Reputation decrease too lenient");
        assertLt(newRep, currentRep, "Reputation should decrease on failure");
    }

    function testEMA_MaxReputationCap() public pure {
        // Rep at max, successful job should stay at max
        uint256 currentRep = 1000;
        uint256 jobScore = 900;
        uint256 jobValue = 10 ether;

        uint256 newRep = ReputationMath.updateReputationEMA(currentRep, jobScore, jobValue);

        assertLe(newRep, 1000, "Reputation exceeded maximum");
    }

    function testEMA_MinReputationFloor() public pure {
        // Rep at minimum, failed job should stay at minimum
        uint256 currentRep = 0;
        uint256 jobScore = 100;
        uint256 jobValue = 1 ether;

        uint256 newRep = ReputationMath.updateReputationEMA(currentRep, jobScore, jobValue);

        assertGe(newRep, 0, "Reputation went below minimum");
    }

    function testEMA_ConsistentSuccess() public pure {
        // Multiple successful jobs should gradually increase reputation
        uint256 rep = 500;
        uint256 jobValue = 1 ether;

        // Simulate 5 successful jobs
        for (uint i = 0; i < 5; i++) {
            uint256 newRep = ReputationMath.updateReputationEMA(rep, 900, jobValue);
            assertGt(newRep, rep, "Reputation should increase on success");
            rep = newRep;
        }

        // After 5 successes, should be significantly higher than 500
        assertGt(rep, 700, "Reputation should increase significantly after multiple successes");
    }

    /**
     * TEST SUITE: Confidence Score
     * Tests statistical confidence scoring
     */

    function testConfidence_NoJobs() public pure {
        // No jobs should give 0 confidence
        uint256 reputation = 900;
        uint256 jobsCompleted = 0;
        uint256 jobsFailed = 0;

        uint256 confidence = ReputationMath.calculateConfidenceScore(
            reputation,
            jobsCompleted,
            jobsFailed
        );

        assertEq(confidence, 0, "Confidence should be 0 with no jobs");
    }

    function testConfidence_FewJobs() public pure {
        // Few jobs should have reduced confidence due to sample size
        uint256 reputation = 900;
        uint256 jobsCompleted = 10;
        uint256 jobsFailed = 0;

        uint256 confidence = ReputationMath.calculateConfidenceScore(
            reputation,
            jobsCompleted,
            jobsFailed
        );

        // sqrt(10/100) ≈ 0.316, so confidence ≈ 900 * 0.316 * 1.0 ≈ 284
        assertGe(confidence, 270, "Confidence too low for 10 jobs");
        assertLe(confidence, 300, "Confidence too high for 10 jobs");
        assertLt(confidence, reputation, "Confidence should be less than reputation with few jobs");
    }

    function testConfidence_ManyJobs_NoFailures() public pure {
        // 100 jobs with no failures should give confidence ≈ reputation
        uint256 reputation = 900;
        uint256 jobsCompleted = 100;
        uint256 jobsFailed = 0;

        uint256 confidence = ReputationMath.calculateConfidenceScore(
            reputation,
            jobsCompleted,
            jobsFailed
        );

        // sqrt(100/100) = 1.0, so confidence ≈ 900 * 1.0 * 1.0 = 900
        assertGe(confidence, 890, "Confidence too low for 100 jobs");
        assertLe(confidence, 910, "Confidence too high for 100 jobs");
    }

    function testConfidence_WithFailures() public pure {
        // Jobs with failures should reduce confidence
        uint256 reputation = 900;
        uint256 jobsCompleted = 100;
        uint256 jobsFailed = 10;

        uint256 confidence = ReputationMath.calculateConfidenceScore(
            reputation,
            jobsCompleted,
            jobsFailed
        );

        // failureRate = 10/110 ≈ 0.091
        // confidence ≈ 900 * 1.0 * (1-0.091) ≈ 818
        assertGe(confidence, 800, "Confidence too low with 10% failure rate");
        assertLe(confidence, 830, "Confidence too high with 10% failure rate");
    }

    function testConfidence_ManyJobs_HighConfidence() public pure {
        // 400 jobs should have higher confidence multiplier
        uint256 reputation = 850;
        uint256 jobsCompleted = 400;
        uint256 jobsFailed = 5;

        uint256 confidence = ReputationMath.calculateConfidenceScore(
            reputation,
            jobsCompleted,
            jobsFailed
        );

        // sqrt(400/100) = 2.0
        // failureRate = 5/405 ≈ 0.0123
        // confidence ≈ 850 * 2.0 * (1-0.0123) ≈ 1679
        assertGe(confidence, 1650, "Confidence too low for 400 jobs");
        assertLe(confidence, 1710, "Confidence too high for 400 jobs");
        assertGt(confidence, reputation, "Confidence should exceed reputation with many jobs");
    }

    function testConfidence_HighFailureRate() public pure {
        // High failure rate should severely reduce confidence
        uint256 reputation = 800;
        uint256 jobsCompleted = 100;
        uint256 jobsFailed = 50;

        uint256 confidence = ReputationMath.calculateConfidenceScore(
            reputation,
            jobsCompleted,
            jobsFailed
        );

        // failureRate = 50/150 ≈ 0.333
        // confidence ≈ 800 * 1.0 * 0.667 ≈ 533
        assertGe(confidence, 520, "Confidence too low with high failure rate");
        assertLe(confidence, 550, "Confidence too high with high failure rate");
    }

    /**
     * TEST SUITE: Edge Cases
     */

    function testEdgeCase_MaxValues() public pure {
        // Test with maximum safe values
        uint256 currentRep = 1000;
        uint256 jobScore = 900;
        uint256 jobValue = type(uint128).max; // Very large value

        // Should not revert and should return valid reputation
        uint256 newRep = ReputationMath.updateReputationEMA(currentRep, jobScore, jobValue);

        assertLe(newRep, 1000, "Reputation exceeded max");
        assertGe(newRep, 0, "Reputation went negative");
    }

    function testEdgeCase_ExtremeDays() public pure {
        // Test with very long time period
        uint256 baseScore = 1000;
        uint256 daysElapsed = 3650; // 10 years

        uint256 decayedScore = ReputationMath.calculateTimeDecay(baseScore, daysElapsed);

        // After 10 years, score should be essentially zero (acceptable due to rounding)
        assertLe(decayedScore, 1, "Score should be negligible after 10 years");
    }
}
