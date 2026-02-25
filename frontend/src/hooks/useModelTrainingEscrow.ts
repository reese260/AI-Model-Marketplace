"use client";

import { useReadContract } from "wagmi";
import { ModelTrainingEscrowAbi } from "@/contracts/abis/ModelTrainingEscrow";
import { useContractAddress } from "@/config/contracts";

function useModelTrainingEscrowAddress() {
  return useContractAddress("ModelTrainingEscrow");
}

export function useGetEscrow(jobId: `0x${string}`) {
  const address = useModelTrainingEscrowAddress();
  return useReadContract({
    address,
    abi: ModelTrainingEscrowAbi,
    functionName: "getEscrow",
    args: [jobId],
  });
}

export function useGetEscrowStatus(jobId: `0x${string}`) {
  const address = useModelTrainingEscrowAddress();
  return useReadContract({
    address,
    abi: ModelTrainingEscrowAbi,
    functionName: "getEscrowStatus",
    args: [jobId],
  });
}
