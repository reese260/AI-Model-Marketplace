"use client";

import {
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { ReputationNFTAbi } from "@/contracts/abis/ReputationNFT";
import { useContractAddress } from "@/config/contracts";

function useReputationNFTAddress() {
  return useContractAddress("ReputationNFT");
}

export function useIsProviderRegistered(provider: `0x${string}` | undefined) {
  const address = useReputationNFTAddress();
  return useReadContract({
    address,
    abi: ReputationNFTAbi,
    functionName: "isProviderRegistered",
    args: provider ? [provider] : undefined,
    query: { enabled: !!provider },
  });
}

export function useGetProviderReputation(provider: `0x${string}` | undefined) {
  const address = useReputationNFTAddress();
  return useReadContract({
    address,
    abi: ReputationNFTAbi,
    functionName: "getProviderReputation",
    args: provider ? [provider] : undefined,
    query: { enabled: !!provider },
  });
}

export function useGetConfidenceScore(provider: `0x${string}` | undefined) {
  const address = useReputationNFTAddress();
  return useReadContract({
    address,
    abi: ReputationNFTAbi,
    functionName: "getProviderConfidenceScore",
    args: provider ? [provider] : undefined,
    query: { enabled: !!provider },
  });
}

export function useRegisterProvider() {
  const address = useReputationNFTAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const registerSelf = () => {
    writeContract({
      address,
      abi: ReputationNFTAbi,
      functionName: "registerSelf",
    });
  };

  return { registerSelf, hash, error, isPending, isConfirming, isSuccess };
}
