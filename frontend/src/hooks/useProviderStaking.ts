"use client";

import {
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { ProviderStakingAbi } from "@/contracts/abis/ProviderStaking";
import { useContractAddress } from "@/config/contracts";

function useProviderStakingAddress() {
  return useContractAddress("ProviderStaking");
}

export function useGetStakeInfo(provider: `0x${string}` | undefined) {
  const address = useProviderStakingAddress();
  return useReadContract({
    address,
    abi: ProviderStakingAbi,
    functionName: "getStakeInfo",
    args: provider ? [provider] : undefined,
    query: { enabled: !!provider },
  });
}

export function useMinDataProviderStake() {
  const address = useProviderStakingAddress();
  return useReadContract({
    address,
    abi: ProviderStakingAbi,
    functionName: "minDataProviderStake",
  });
}

export function useMinComputeProviderStake() {
  const address = useProviderStakingAddress();
  return useReadContract({
    address,
    abi: ProviderStakingAbi,
    functionName: "minComputeProviderStake",
  });
}

export function useStake() {
  const address = useProviderStakingAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const stake = (providerType: number, value: bigint) => {
    writeContract({
      address,
      abi: ProviderStakingAbi,
      functionName: "stake",
      args: [providerType],
      value,
    });
  };

  return { stake, hash, error, isPending, isConfirming, isSuccess };
}

export function useUnstake() {
  const address = useProviderStakingAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const unstake = (amount: bigint) => {
    writeContract({
      address,
      abi: ProviderStakingAbi,
      functionName: "unstake",
      args: [amount],
    });
  };

  return { unstake, hash, error, isPending, isConfirming, isSuccess };
}
