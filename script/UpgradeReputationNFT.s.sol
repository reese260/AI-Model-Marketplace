// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../src/ReputationNFT.sol";

/**
 * @title UpgradeReputationNFT
 * @notice Upgrades ReputationNFT to add permissionless self-registration via registerSelf()
 */
contract UpgradeReputationNFT is Script {
    address constant REPUTATION_NFT_PROXY = 0xAEd7fCD03baFCe90520b6C83F0fC8Dc736AebdE2;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        console.log("=== Upgrading ReputationNFT ===");
        console.log("Proxy:", REPUTATION_NFT_PROXY);

        vm.startBroadcast(deployerKey);

        ReputationNFT newImpl = new ReputationNFT();
        console.log("New implementation:", address(newImpl));

        UUPSUpgradeable(REPUTATION_NFT_PROXY).upgradeToAndCall(address(newImpl), "");
        console.log("Upgrade complete - registerSelf() now available");

        vm.stopBroadcast();
    }
}
