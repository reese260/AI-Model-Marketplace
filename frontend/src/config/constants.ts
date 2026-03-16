import { parseEther } from "viem";

// Mirrored from Deploy.s.sol
export const MIN_DATA_PROVIDER_STAKE = parseEther("0.1");
export const MIN_COMPUTE_PROVIDER_STAKE = parseEther("0.5");
export const CHALLENGE_PERIOD = 86400; // 24 hours in seconds
export const PLATFORM_FEE_BPS = 1000; // 10%
export const MAX_PROVIDER_SHARE_BPS = 9000; // 90% (remaining goes to platform)

// Reputation constants from ReputationNFT.sol
export const SUCCESS_SCORE = 900;
export const FAILURE_SCORE = 100;
export const ZK_BONUS_BPS = 500; // 5%
export const MAX_REPUTATION_SCORE = 1000;

// Supported chain IDs
export const SUPPORTED_CHAIN_IDS = [80002, 137] as const;
export const DEFAULT_CHAIN_ID = 80002; // Amoy

// Block number when contracts were first deployed (for event queries)
export const DEPLOYMENT_BLOCK = 35073004n;
