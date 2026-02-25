"use client";

import { useAccount } from "wagmi";
import { useIsProviderRegistered } from "./useReputationNFT";
import { useGetStakeInfo } from "./useProviderStaking";
import { ProviderType, type StakeInfo } from "@/lib/types";

export function useUserRole() {
  const { address, isConnected } = useAccount();

  const { data: isRegistered, isLoading: isRegisteredLoading } =
    useIsProviderRegistered(address);

  const { data: stakeInfoRaw, isLoading: isStakeLoading } =
    useGetStakeInfo(address);

  const isLoading = isRegisteredLoading || isStakeLoading;

  const stakeInfo = stakeInfoRaw as unknown as StakeInfo | undefined;

  const isProvider = !!isRegistered;
  const isDataProvider =
    isProvider &&
    stakeInfo !== undefined &&
    Number(stakeInfo.providerType) === ProviderType.DATA &&
    stakeInfo.isActive;
  const isComputeProvider =
    isProvider &&
    stakeInfo !== undefined &&
    Number(stakeInfo.providerType) === ProviderType.COMPUTE &&
    stakeInfo.isActive;
  const hasStake =
    stakeInfo !== undefined && stakeInfo.amount > 0n;

  return {
    address,
    isConnected,
    isRegistered: isProvider,
    isDataProvider,
    isComputeProvider,
    hasStake,
    stakeInfo,
    isLoading,
  };
}
