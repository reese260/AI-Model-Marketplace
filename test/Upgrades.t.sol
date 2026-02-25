// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../src/ReputationNFT.sol";
import "../src/ProviderStaking.sol";
import "../src/TrainingVerification.sol";
import "../src/ModelTrainingEscrow.sol";
import "../src/ZKTrainingVerifier.sol";
import "../src/JobMarketplace.sol";
import "../src/Groth16Verifier.sol";

/**
 * @title UpgradesTest
 * @notice Tests for UUPS upgrade behavior: double-init prevention, owner-only upgrade, state preservation
 */
contract UpgradesTest is Test {
    address public owner;
    address public nonOwner;
    address public feeRecipient;

    function setUp() public {
        owner = address(this);
        nonOwner = makeAddr("nonOwner");
        feeRecipient = makeAddr("feeRecipient");
    }

    // ============ Cannot initialize twice ============

    function testCannotInitializeReputationNFTTwice() public {
        ReputationNFT proxy = ReputationNFT(address(new ERC1967Proxy(
            address(new ReputationNFT()),
            abi.encodeCall(ReputationNFT.initialize, ())
        )));

        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        proxy.initialize();
    }

    function testCannotInitializeProviderStakingTwice() public {
        ProviderStaking proxy = ProviderStaking(address(new ERC1967Proxy(
            address(new ProviderStaking()),
            abi.encodeCall(ProviderStaking.initialize, (0.1 ether, 0.5 ether))
        )));

        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        proxy.initialize(0.2 ether, 1 ether);
    }

    function testCannotInitializeTrainingVerificationTwice() public {
        TrainingVerification proxy = TrainingVerification(address(new ERC1967Proxy(
            address(new TrainingVerification()),
            abi.encodeCall(TrainingVerification.initialize, (24 hours))
        )));

        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        proxy.initialize(48 hours);
    }

    function testCannotInitializeModelTrainingEscrowTwice() public {
        ModelTrainingEscrow proxy = ModelTrainingEscrow(address(new ERC1967Proxy(
            address(new ModelTrainingEscrow()),
            abi.encodeCall(ModelTrainingEscrow.initialize, (1000, feeRecipient))
        )));

        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        proxy.initialize(2000, feeRecipient);
    }

    function testCannotInitializeZKTrainingVerifierTwice() public {
        Groth16Verifier groth16 = new Groth16Verifier();
        ZKTrainingVerifier proxy = ZKTrainingVerifier(address(new ERC1967Proxy(
            address(new ZKTrainingVerifier()),
            abi.encodeCall(ZKTrainingVerifier.initialize, (address(groth16)))
        )));

        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        proxy.initialize(address(groth16));
    }

    function testCannotInitializeJobMarketplaceTwice() public {
        // Deploy dependencies
        ReputationNFT repNFT = ReputationNFT(address(new ERC1967Proxy(
            address(new ReputationNFT()),
            abi.encodeCall(ReputationNFT.initialize, ())
        )));
        ProviderStaking staking = ProviderStaking(address(new ERC1967Proxy(
            address(new ProviderStaking()),
            abi.encodeCall(ProviderStaking.initialize, (0.1 ether, 0.5 ether))
        )));
        TrainingVerification tv = TrainingVerification(address(new ERC1967Proxy(
            address(new TrainingVerification()),
            abi.encodeCall(TrainingVerification.initialize, (24 hours))
        )));
        ModelTrainingEscrow esc = ModelTrainingEscrow(address(new ERC1967Proxy(
            address(new ModelTrainingEscrow()),
            abi.encodeCall(ModelTrainingEscrow.initialize, (1000, feeRecipient))
        )));

        JobMarketplace proxy = JobMarketplace(address(new ERC1967Proxy(
            address(new JobMarketplace()),
            abi.encodeCall(JobMarketplace.initialize, (
                address(repNFT), address(staking), address(tv), address(esc)
            ))
        )));

        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        proxy.initialize(address(repNFT), address(staking), address(tv), address(esc));
    }

    // ============ Only owner can upgrade ============

    function testOnlyOwnerCanUpgradeReputationNFT() public {
        ReputationNFT proxy = ReputationNFT(address(new ERC1967Proxy(
            address(new ReputationNFT()),
            abi.encodeCall(ReputationNFT.initialize, ())
        )));

        ReputationNFT newImpl = new ReputationNFT();

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(newImpl), "");
    }

    function testOnlyOwnerCanUpgradeProviderStaking() public {
        ProviderStaking proxy = ProviderStaking(address(new ERC1967Proxy(
            address(new ProviderStaking()),
            abi.encodeCall(ProviderStaking.initialize, (0.1 ether, 0.5 ether))
        )));

        ProviderStaking newImpl = new ProviderStaking();

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(newImpl), "");
    }

    function testOnlyOwnerCanUpgradeJobMarketplace() public {
        ReputationNFT repNFT = ReputationNFT(address(new ERC1967Proxy(
            address(new ReputationNFT()),
            abi.encodeCall(ReputationNFT.initialize, ())
        )));
        ProviderStaking staking = ProviderStaking(address(new ERC1967Proxy(
            address(new ProviderStaking()),
            abi.encodeCall(ProviderStaking.initialize, (0.1 ether, 0.5 ether))
        )));
        TrainingVerification tv = TrainingVerification(address(new ERC1967Proxy(
            address(new TrainingVerification()),
            abi.encodeCall(TrainingVerification.initialize, (24 hours))
        )));
        ModelTrainingEscrow esc = ModelTrainingEscrow(address(new ERC1967Proxy(
            address(new ModelTrainingEscrow()),
            abi.encodeCall(ModelTrainingEscrow.initialize, (1000, feeRecipient))
        )));
        JobMarketplace proxy = JobMarketplace(address(new ERC1967Proxy(
            address(new JobMarketplace()),
            abi.encodeCall(JobMarketplace.initialize, (
                address(repNFT), address(staking), address(tv), address(esc)
            ))
        )));

        JobMarketplace newImpl = new JobMarketplace();

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", nonOwner));
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(newImpl), "");
    }

    // ============ State preserved across upgrades ============

    function testStatePreservedAcrossReputationNFTUpgrade() public {
        ReputationNFT proxy = ReputationNFT(address(new ERC1967Proxy(
            address(new ReputationNFT()),
            abi.encodeCall(ReputationNFT.initialize, ())
        )));

        // Create state
        address provider = makeAddr("provider");
        vm.prank(provider);
        proxy.registerProvider(provider);
        assertTrue(proxy.isProviderRegistered(provider));

        // Upgrade
        ReputationNFT newImpl = new ReputationNFT();
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(newImpl), "");

        // Verify state is preserved
        assertTrue(proxy.isProviderRegistered(provider));
        ReputationNFT.ReputationData memory data = proxy.getProviderReputation(provider);
        assertEq(data.score, 500);
    }

    function testStatePreservedAcrossProviderStakingUpgrade() public {
        ProviderStaking proxy = ProviderStaking(address(new ERC1967Proxy(
            address(new ProviderStaking()),
            abi.encodeCall(ProviderStaking.initialize, (0.1 ether, 0.5 ether))
        )));

        // Create state
        address provider = makeAddr("staker");
        vm.deal(provider, 1 ether);
        vm.prank(provider);
        proxy.stake{value: 0.5 ether}(ProviderStaking.ProviderType.COMPUTE);

        ProviderStaking.StakeInfo memory infoBefore = proxy.getStakeInfo(provider);
        assertEq(infoBefore.amount, 0.5 ether);

        // Upgrade
        ProviderStaking newImpl = new ProviderStaking();
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(newImpl), "");

        // Verify state preserved
        ProviderStaking.StakeInfo memory infoAfter = proxy.getStakeInfo(provider);
        assertEq(infoAfter.amount, 0.5 ether);
        assertTrue(infoAfter.isActive);
        assertEq(proxy.minDataProviderStake(), 0.1 ether);
        assertEq(proxy.minComputeProviderStake(), 0.5 ether);
    }

    function testOwnerCanUpgradeSuccessfully() public {
        ReputationNFT proxy = ReputationNFT(address(new ERC1967Proxy(
            address(new ReputationNFT()),
            abi.encodeCall(ReputationNFT.initialize, ())
        )));

        ReputationNFT newImpl = new ReputationNFT();

        // Owner can upgrade (no revert)
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(newImpl), "");

        // Contract still works after upgrade
        address provider = makeAddr("provider");
        vm.prank(provider);
        proxy.registerProvider(provider);
        assertTrue(proxy.isProviderRegistered(provider));
    }

    // ============ Cannot initialize implementation directly ============

    function testCannotInitializeImplementationDirectly() public {
        ReputationNFT impl = new ReputationNFT();

        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        impl.initialize();
    }
}
