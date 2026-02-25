// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/SlashingMath.sol";

contract SlashingMathTest is Test {
    /**
     * TEST SUITE: Sigmoid Severity Multiplier
     * Tests the sigmoid function for smooth severity scaling
     */

    function testSigmoid_ZeroSeverity() public pure {
        // Severity 0 should give very low multiplier (not exactly 0)
        uint256 severity = 0;
        SD59x18 multiplier = SlashingMath.calculateSeverityMultiplier(severity);

        // Should be close to 0 but not exactly 0 (sigmoid asymptote)
        assertGt(multiplier.unwrap(), 0, "Multiplier should be greater than 0");
        assertLt(multiplier.unwrap(), 0.02e18, "Multiplier too high for severity 0");
    }

    function testSigmoid_LowSeverity() public pure {
        // Severity 25 should give low multiplier
        uint256 severity = 25;
        SD59x18 multiplier = SlashingMath.calculateSeverityMultiplier(severity);

        // Should be in low range (0.05 - 0.15)
        assertGe(multiplier.unwrap(), 0.05e18, "Multiplier too low for severity 25");
        assertLe(multiplier.unwrap(), 0.15e18, "Multiplier too high for severity 25");
    }

    function testSigmoid_MidSeverity_InflectionPoint() public pure {
        // Severity 50 (inflection point) should give exactly 0.5
        uint256 severity = 50;
        SD59x18 multiplier = SlashingMath.calculateSeverityMultiplier(severity);

        // At inflection point, sigmoid should be exactly 0.5
        assertGe(multiplier.unwrap(), 0.49e18, "Multiplier too low at inflection");
        assertLe(multiplier.unwrap(), 0.51e18, "Multiplier too high at inflection");
    }

    function testSigmoid_HighSeverity() public pure {
        // Severity 75 should give high multiplier
        uint256 severity = 75;
        SD59x18 multiplier = SlashingMath.calculateSeverityMultiplier(severity);

        // Should be in high range (0.85 - 0.95)
        assertGe(multiplier.unwrap(), 0.85e18, "Multiplier too low for severity 75");
        assertLe(multiplier.unwrap(), 0.95e18, "Multiplier too high for severity 75");
    }

    function testSigmoid_MaxSeverity() public pure {
        // Severity 100 should give very high multiplier (not exactly 1)
        uint256 severity = 100;
        SD59x18 multiplier = SlashingMath.calculateSeverityMultiplier(severity);

        // Should be close to 1 but not exactly 1 (sigmoid asymptote)
        assertGt(multiplier.unwrap(), 0.98e18, "Multiplier too low for severity 100");
        assertLt(multiplier.unwrap(), 1.0e18, "Multiplier should not reach exactly 1");
    }

    function testSigmoid_Monotonicity() public pure {
        // Sigmoid should be monotonically increasing
        SD59x18 prev = SlashingMath.calculateSeverityMultiplier(0);

        for (uint256 severity = 10; severity <= 100; severity += 10) {
            SD59x18 current = SlashingMath.calculateSeverityMultiplier(severity);
            assertGt(current.unwrap(), prev.unwrap(), "Sigmoid should be monotonically increasing");
            prev = current;
        }
    }

    /**
     * TEST SUITE: Repeat Offender Multiplier
     * Tests exponential penalty growth for repeat violations
     */

    function testRepeatOffender_FirstOffense() public pure {
        // First offense (count=0) should have 1.0x multiplier
        uint256 violationCount = 0;
        SD59x18 multiplier = SlashingMath.calculateRepeatOffenderMultiplier(violationCount);

        assertEq(multiplier.unwrap(), 1.0e18, "First offense should be 1.0x");
    }

    function testRepeatOffender_SecondOffense() public pure {
        // Second offense (count=1) should have 1.5x multiplier
        uint256 violationCount = 1;
        SD59x18 multiplier = SlashingMath.calculateRepeatOffenderMultiplier(violationCount);

        assertEq(multiplier.unwrap(), 1.5e18, "Second offense should be 1.5x");
    }

    function testRepeatOffender_ThirdOffense() public pure {
        // Third offense (count=2) should have 2.25x multiplier (1.5^2)
        uint256 violationCount = 2;
        SD59x18 multiplier = SlashingMath.calculateRepeatOffenderMultiplier(violationCount);

        // Allow tiny rounding error from fixed-point math
        assertGe(multiplier.unwrap(), 2.249e18, "Third offense multiplier too low");
        assertLe(multiplier.unwrap(), 2.251e18, "Third offense multiplier too high");
    }

    function testRepeatOffender_FourthOffense() public pure {
        // Fourth offense (count=3) should have 3.375x multiplier (1.5^3)
        uint256 violationCount = 3;
        SD59x18 multiplier = SlashingMath.calculateRepeatOffenderMultiplier(violationCount);

        // Allow small rounding error
        assertGe(multiplier.unwrap(), 3.37e18, "Fourth offense multiplier too low");
        assertLe(multiplier.unwrap(), 3.38e18, "Fourth offense multiplier too high");
    }

    function testRepeatOffender_Cap() public pure {
        // Many violations should cap at 5.0x
        uint256 violationCount = 10;
        SD59x18 multiplier = SlashingMath.calculateRepeatOffenderMultiplier(violationCount);

        assertEq(multiplier.unwrap(), 5.0e18, "Repeat offender multiplier should cap at 5.0x");
    }

    function testRepeatOffender_JustBeforeCap() public pure {
        // 1.5^4 = 5.0625, should be capped
        uint256 violationCount = 4;
        SD59x18 multiplier = SlashingMath.calculateRepeatOffenderMultiplier(violationCount);

        assertEq(multiplier.unwrap(), 5.0e18, "Should be capped at 5.0x");
    }

    function testRepeatOffender_ExponentialGrowth() public pure {
        // Each offense should multiply by 1.5
        SD59x18 mult1 = SlashingMath.calculateRepeatOffenderMultiplier(0);
        SD59x18 mult2 = SlashingMath.calculateRepeatOffenderMultiplier(1);
        SD59x18 mult3 = SlashingMath.calculateRepeatOffenderMultiplier(2);

        // mult2 should be 1.5x mult1
        assertEq(mult2.unwrap(), mult1.unwrap() * 3 / 2, "Second offense should be 1.5x first");

        // mult3 should be approximately 1.5x mult2 (allow tiny rounding error)
        int256 expected = mult2.unwrap() * 3 / 2;
        int256 actual = mult3.unwrap();
        int256 diff = actual > expected ? actual - expected : expected - actual;
        assertLt(diff, 1e15, "Third offense should be very close to 1.5x second");
    }

    /**
     * TEST SUITE: Reputation Adjustment
     * Tests reputation-weighted penalty adjustments
     */

    function testReputationAdjustment_MaxReputation() public pure {
        // Max reputation (1000) should have minimum adjustment (1.0x)
        uint256 reputation = 1000;
        SD59x18 adjustment = SlashingMath.calculateReputationAdjustment(reputation);

        assertEq(adjustment.unwrap(), 1.0e18, "Max reputation should have 1.0x adjustment");
    }

    function testReputationAdjustment_MidReputation() public pure {
        // Mid reputation (500) should have moderate adjustment
        uint256 reputation = 500;
        SD59x18 adjustment = SlashingMath.calculateReputationAdjustment(reputation);

        // 1 + (1000-500)/2000 = 1.25
        assertEq(adjustment.unwrap(), 1.25e18, "Mid reputation should have 1.25x adjustment");
    }

    function testReputationAdjustment_LowReputation() public pure {
        // Low reputation (200) should have higher adjustment
        uint256 reputation = 200;
        SD59x18 adjustment = SlashingMath.calculateReputationAdjustment(reputation);

        // 1 + (1000-200)/2000 = 1.4
        assertEq(adjustment.unwrap(), 1.4e18, "Low reputation should have 1.4x adjustment");
    }

    function testReputationAdjustment_ZeroReputation() public pure {
        // Zero reputation should have max adjustment (1.5x)
        uint256 reputation = 0;
        SD59x18 adjustment = SlashingMath.calculateReputationAdjustment(reputation);

        assertEq(adjustment.unwrap(), 1.5e18, "Zero reputation should have 1.5x adjustment");
    }

    function testReputationAdjustment_Linear() public pure {
        // Adjustment should be linear with reputation
        SD59x18 adj1000 = SlashingMath.calculateReputationAdjustment(1000);
        SD59x18 adj500 = SlashingMath.calculateReputationAdjustment(500);
        SD59x18 adj0 = SlashingMath.calculateReputationAdjustment(0);

        // Verify linear progression
        int256 diff1 = adj500.unwrap() - adj1000.unwrap();
        int256 diff2 = adj0.unwrap() - adj500.unwrap();

        assertEq(diff1, diff2, "Adjustment should be linear");
    }

    /**
     * TEST SUITE: Stake Risk Factor
     * Tests square root scaling of stake risk
     */

    function testStakeRisk_NoRisk() public pure {
        // No stake at risk should give 0 factor
        uint256 stakeAtRisk = 0;
        uint256 totalStake = 10 ether;

        SD59x18 riskFactor = SlashingMath.calculateStakeRiskFactor(stakeAtRisk, totalStake);

        assertEq(riskFactor.unwrap(), 0, "No stake at risk should give 0 factor");
    }

    function testStakeRisk_FullRisk() public pure {
        // 100% stake at risk should give 1.0 factor
        uint256 stakeAtRisk = 10 ether;
        uint256 totalStake = 10 ether;

        SD59x18 riskFactor = SlashingMath.calculateStakeRiskFactor(stakeAtRisk, totalStake);

        assertEq(riskFactor.unwrap(), 1.0e18, "Full risk should give 1.0 factor");
    }

    function testStakeRisk_QuarterRisk() public pure {
        // 25% stake at risk should give 0.5 factor (sqrt(0.25) = 0.5)
        uint256 stakeAtRisk = 5 ether;
        uint256 totalStake = 20 ether;

        SD59x18 riskFactor = SlashingMath.calculateStakeRiskFactor(stakeAtRisk, totalStake);

        assertEq(riskFactor.unwrap(), 0.5e18, "25% risk should give 0.5 factor");
    }

    function testStakeRisk_SmallRisk() public pure {
        // 1% stake at risk should give 0.1 factor (sqrt(0.01) = 0.1)
        uint256 stakeAtRisk = 1 ether;
        uint256 totalStake = 100 ether;

        SD59x18 riskFactor = SlashingMath.calculateStakeRiskFactor(stakeAtRisk, totalStake);

        assertEq(riskFactor.unwrap(), 0.1e18, "1% risk should give 0.1 factor");
    }

    function testStakeRisk_ZeroTotalStake() public pure {
        // Zero total stake should return 0 (edge case protection)
        uint256 stakeAtRisk = 1 ether;
        uint256 totalStake = 0;

        SD59x18 riskFactor = SlashingMath.calculateStakeRiskFactor(stakeAtRisk, totalStake);

        assertEq(riskFactor.unwrap(), 0, "Zero total stake should give 0 factor");
    }

    /**
     * TEST SUITE: Complete Slash Amount Calculation
     * Tests the full slashing formula with all factors combined
     */

    function testCompleteSlash_FirstOffense_MinorViolation() public pure {
        // Scenario: First-time offender, minor violation
        uint256 baseAmount = 1 ether;
        uint256 severity = 20; // Minor
        uint256 violationCount = 0; // First offense
        uint256 reputation = 800; // Good
        uint256 stakeAtRisk = 2 ether;
        uint256 totalStake = 10 ether;

        uint256 slashAmount = SlashingMath.calculateSlashAmount(
            baseAmount,
            severity,
            violationCount,
            reputation,
            stakeAtRisk,
            totalStake
        );

        // Should be very lenient (< 10% of base)
        assertLt(slashAmount, 0.1 ether, "Slash too harsh for first minor offense");
        assertGt(slashAmount, 0, "Slash should not be zero");
    }

    function testCompleteSlash_RepeatOffender_ModerateSeverity() public pure {
        // Scenario: Repeat offender, moderate violation
        uint256 baseAmount = 1 ether;
        uint256 severity = 50; // Moderate
        uint256 violationCount = 2; // Third offense
        uint256 reputation = 600; // Average
        uint256 stakeAtRisk = 5 ether;
        uint256 totalStake = 15 ether;

        uint256 slashAmount = SlashingMath.calculateSlashAmount(
            baseAmount,
            severity,
            violationCount,
            reputation,
            stakeAtRisk,
            totalStake
        );

        // Should be substantial (50-90% of base due to repeat offense)
        assertGe(slashAmount, 0.5 ether, "Slash too lenient for repeat offender");
        assertLe(slashAmount, 1.0 ether, "Slash should not exceed base significantly");
    }

    function testCompleteSlash_SerialOffender_Critical() public pure {
        // Scenario: Serial offender, critical violation
        uint256 baseAmount = 2 ether;
        uint256 severity = 90; // Critical
        uint256 violationCount = 4; // Fifth offense
        uint256 reputation = 300; // Poor
        uint256 stakeAtRisk = 10 ether;
        uint256 totalStake = 10 ether; // Full risk

        uint256 slashAmount = SlashingMath.calculateSlashAmount(
            baseAmount,
            severity,
            violationCount,
            reputation,
            stakeAtRisk,
            totalStake
        );

        // Should be very high due to all negative factors
        assertGe(slashAmount, 10 ether, "Slash too lenient for serial critical offender");

        // Note: In practice this would be capped at totalStake by the contract
    }

    function testCompleteSlash_HighReputation_FirstOffense() public pure {
        // Scenario: Trusted provider, first violation
        uint256 baseAmount = 1 ether;
        uint256 severity = 40; // Moderate-low
        uint256 violationCount = 0; // First offense
        uint256 reputation = 950; // High trust
        uint256 stakeAtRisk = 3 ether;
        uint256 totalStake = 20 ether;

        uint256 slashAmount = SlashingMath.calculateSlashAmount(
            baseAmount,
            severity,
            violationCount,
            reputation,
            stakeAtRisk,
            totalStake
        );

        // Should be relatively lenient due to high reputation
        assertLt(slashAmount, 0.3 ether, "Slash too harsh for trusted provider");
    }

    function testCompleteSlash_LowReputation_FirstOffense() public pure {
        // Scenario: Untrusted provider, first violation
        uint256 baseAmount = 1 ether;
        uint256 severity = 40; // Moderate-low (same as above)
        uint256 violationCount = 0; // First offense
        uint256 reputation = 100; // Low trust
        uint256 stakeAtRisk = 3 ether;
        uint256 totalStake = 20 ether;

        uint256 slashAmount = SlashingMath.calculateSlashAmount(
            baseAmount,
            severity,
            violationCount,
            reputation,
            stakeAtRisk,
            totalStake
        );

        // Should be harsher than high reputation case
        assertGt(slashAmount, 0.15 ether, "Slash too lenient for untrusted provider");
    }

    function testCompleteSlash_ZeroBaseAmount() public pure {
        // Edge case: zero base amount
        uint256 baseAmount = 0;
        uint256 severity = 50;
        uint256 violationCount = 2;
        uint256 reputation = 500;
        uint256 stakeAtRisk = 5 ether;
        uint256 totalStake = 10 ether;

        uint256 slashAmount = SlashingMath.calculateSlashAmount(
            baseAmount,
            severity,
            violationCount,
            reputation,
            stakeAtRisk,
            totalStake
        );

        assertEq(slashAmount, 0, "Zero base should result in zero slash");
    }

    function testCompleteSlash_MaxSeverity() public pure {
        // Edge case: maximum severity (100)
        uint256 baseAmount = 1 ether;
        uint256 severity = 100; // Max severity
        uint256 violationCount = 0;
        uint256 reputation = 500;
        uint256 stakeAtRisk = 5 ether;
        uint256 totalStake = 10 ether;

        uint256 slashAmount = SlashingMath.calculateSlashAmount(
            baseAmount,
            severity,
            violationCount,
            reputation,
            stakeAtRisk,
            totalStake
        );

        // Should be close to base * other factors (severity ≈ 0.993)
        assertGt(slashAmount, 0.6 ether, "Max severity slash too low");
    }

    /**
     * TEST SUITE: Comparative Analysis
     * Tests comparing different scenarios
     */

    function testComparison_SeverityImpact() public pure {
        // Same everything, different severity
        uint256 baseAmount = 1 ether;
        uint256 violationCount = 0;
        uint256 reputation = 700;
        uint256 stakeAtRisk = 5 ether;
        uint256 totalStake = 10 ether;

        uint256 slashLow = SlashingMath.calculateSlashAmount(
            baseAmount, 25, violationCount, reputation, stakeAtRisk, totalStake
        );

        uint256 slashHigh = SlashingMath.calculateSlashAmount(
            baseAmount, 75, violationCount, reputation, stakeAtRisk, totalStake
        );

        assertGt(slashHigh, slashLow, "Higher severity should result in higher slash");
        assertGt(slashHigh, slashLow * 5, "High severity should be significantly more than low");
    }

    function testComparison_ViolationCountImpact() public pure {
        // Same everything, different violation count
        uint256 baseAmount = 1 ether;
        uint256 severity = 50;
        uint256 reputation = 700;
        uint256 stakeAtRisk = 5 ether;
        uint256 totalStake = 10 ether;

        uint256 slashFirst = SlashingMath.calculateSlashAmount(
            baseAmount, severity, 0, reputation, stakeAtRisk, totalStake
        );

        uint256 slashThird = SlashingMath.calculateSlashAmount(
            baseAmount, severity, 2, reputation, stakeAtRisk, totalStake
        );

        assertGt(slashThird, slashFirst, "Repeat offenses should increase slash");
        // Third offense should be 2.25x first offense (all else equal)
        assertGe(slashThird, slashFirst * 2, "Third offense should be at least 2x first");
    }

    function testComparison_ReputationImpact() public pure {
        // Same everything, different reputation
        uint256 baseAmount = 1 ether;
        uint256 severity = 50;
        uint256 violationCount = 0;
        uint256 stakeAtRisk = 5 ether;
        uint256 totalStake = 10 ether;

        uint256 slashHighRep = SlashingMath.calculateSlashAmount(
            baseAmount, severity, violationCount, 900, stakeAtRisk, totalStake
        );

        uint256 slashLowRep = SlashingMath.calculateSlashAmount(
            baseAmount, severity, violationCount, 100, stakeAtRisk, totalStake
        );

        assertGt(slashLowRep, slashHighRep, "Low reputation should result in higher slash");
    }

    function testComparison_StakeRiskImpact() public pure {
        // Same everything, different stake at risk
        uint256 baseAmount = 1 ether;
        uint256 severity = 50;
        uint256 violationCount = 0;
        uint256 reputation = 700;
        uint256 totalStake = 20 ether;

        uint256 slashLowRisk = SlashingMath.calculateSlashAmount(
            baseAmount, severity, violationCount, reputation, 1 ether, totalStake
        );

        uint256 slashHighRisk = SlashingMath.calculateSlashAmount(
            baseAmount, severity, violationCount, reputation, 16 ether, totalStake
        );

        assertGt(slashHighRisk, slashLowRisk, "Higher stake at risk should increase slash");
    }
}
