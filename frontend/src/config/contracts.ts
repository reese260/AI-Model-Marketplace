import { type Address } from "viem";
import { useChainId } from "wagmi";
import { polygon, polygonAmoy } from "wagmi/chains";

export type ContractName =
  | "JobMarketplace"
  | "ReputationNFT"
  | "ProviderStaking"
  | "TrainingVerification"
  | "ModelTrainingEscrow"
  | "ZKTrainingVerifier";

const envAddresses: Record<ContractName, Address | undefined> = {
  JobMarketplace: process.env.NEXT_PUBLIC_JOB_MARKETPLACE_ADDRESS as
    | Address
    | undefined,
  ReputationNFT: process.env.NEXT_PUBLIC_REPUTATION_NFT_ADDRESS as
    | Address
    | undefined,
  ProviderStaking: process.env.NEXT_PUBLIC_PROVIDER_STAKING_ADDRESS as
    | Address
    | undefined,
  TrainingVerification: process.env
    .NEXT_PUBLIC_TRAINING_VERIFICATION_ADDRESS as Address | undefined,
  ModelTrainingEscrow: process.env.NEXT_PUBLIC_MODEL_TRAINING_ESCROW_ADDRESS as
    | Address
    | undefined,
  ZKTrainingVerifier: process.env.NEXT_PUBLIC_ZK_TRAINING_VERIFIER_ADDRESS as
    | Address
    | undefined,
};

// Placeholder addresses for development - replace with actual deployed addresses
const PLACEHOLDER: Address = "0x0000000000000000000000000000000000000000";

const addresses: Record<number, Record<ContractName, Address>> = {
  [polygonAmoy.id]: {
    JobMarketplace: envAddresses.JobMarketplace || PLACEHOLDER,
    ReputationNFT: envAddresses.ReputationNFT || PLACEHOLDER,
    ProviderStaking: envAddresses.ProviderStaking || PLACEHOLDER,
    TrainingVerification: envAddresses.TrainingVerification || PLACEHOLDER,
    ModelTrainingEscrow: envAddresses.ModelTrainingEscrow || PLACEHOLDER,
    ZKTrainingVerifier: envAddresses.ZKTrainingVerifier || PLACEHOLDER,
  },
  [polygon.id]: {
    JobMarketplace: envAddresses.JobMarketplace || PLACEHOLDER,
    ReputationNFT: envAddresses.ReputationNFT || PLACEHOLDER,
    ProviderStaking: envAddresses.ProviderStaking || PLACEHOLDER,
    TrainingVerification: envAddresses.TrainingVerification || PLACEHOLDER,
    ModelTrainingEscrow: envAddresses.ModelTrainingEscrow || PLACEHOLDER,
    ZKTrainingVerifier: envAddresses.ZKTrainingVerifier || PLACEHOLDER,
  },
};

export function getContractAddress(
  chainId: number,
  name: ContractName
): Address {
  return addresses[chainId]?.[name] || PLACEHOLDER;
}

export function useContractAddress(name: ContractName): Address {
  const chainId = useChainId();
  return getContractAddress(chainId, name);
}
