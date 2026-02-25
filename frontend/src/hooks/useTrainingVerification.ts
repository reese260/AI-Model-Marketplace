"use client";

import {
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { TrainingVerificationAbi } from "@/contracts/abis/TrainingVerification";
import { useContractAddress } from "@/config/contracts";

function useTrainingVerificationAddress() {
  return useContractAddress("TrainingVerification");
}

export function useGetSubmission(jobId: `0x${string}`) {
  const address = useTrainingVerificationAddress();
  return useReadContract({
    address,
    abi: TrainingVerificationAbi,
    functionName: "getSubmission",
    args: [jobId],
  });
}

export function useIsTrainingVerified(jobId: `0x${string}`) {
  const address = useTrainingVerificationAddress();
  return useReadContract({
    address,
    abi: TrainingVerificationAbi,
    functionName: "isTrainingVerified",
    args: [jobId],
  });
}

export function useIsInChallengePeriod(jobId: `0x${string}`) {
  const address = useTrainingVerificationAddress();
  return useReadContract({
    address,
    abi: TrainingVerificationAbi,
    functionName: "isInChallengePeriod",
    args: [jobId],
  });
}

export function useChallengeTraining() {
  const address = useTrainingVerificationAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const challengeTraining = (jobId: `0x${string}`, reason: string) => {
    writeContract({
      address,
      abi: TrainingVerificationAbi,
      functionName: "challengeTraining",
      args: [jobId, reason],
    });
  };

  return { challengeTraining, hash, error, isPending, isConfirming, isSuccess };
}

export function useVerifyTraining() {
  const address = useTrainingVerificationAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const verifyTraining = (jobId: `0x${string}`) => {
    writeContract({
      address,
      abi: TrainingVerificationAbi,
      functionName: "verifyTraining",
      args: [jobId],
    });
  };

  return { verifyTraining, hash, error, isPending, isConfirming, isSuccess };
}
