"use client";

import {
  useReadContract,
  useWriteContract,
  useWaitForTransactionReceipt,
} from "wagmi";
import { JobMarketplaceAbi } from "@/contracts/abis/JobMarketplace";
import { useContractAddress } from "@/config/contracts";

function useJobMarketplaceAddress() {
  return useContractAddress("JobMarketplace");
}

export function useGetJob(jobId: `0x${string}`) {
  const address = useJobMarketplaceAddress();
  return useReadContract({
    address,
    abi: JobMarketplaceAbi,
    functionName: "getJob",
    args: [jobId],
    query: { enabled: jobId !== "0x0000000000000000000000000000000000000000000000000000000000000000" },
  });
}

export function useGetJobApplicants(jobId: `0x${string}`) {
  const address = useJobMarketplaceAddress();
  return useReadContract({
    address,
    abi: JobMarketplaceAbi,
    functionName: "getJobApplicants",
    args: [jobId],
  });
}

export function useCreateJob() {
  const address = useJobMarketplaceAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const createJob = (
    jobDetailsIPFS: string,
    dataProviderShare: bigint,
    computeProviderShare: bigint,
    requiredStakeData: bigint,
    requiredStakeCompute: bigint,
    deadline: bigint,
    value: bigint
  ) => {
    writeContract({
      address,
      abi: JobMarketplaceAbi,
      functionName: "createJob",
      args: [jobDetailsIPFS, dataProviderShare, computeProviderShare, requiredStakeData, requiredStakeCompute, deadline],
      value,
    });
  };

  return { createJob, hash, error, isPending, isConfirming, isSuccess };
}

export function useCreateJobWithZK() {
  const address = useJobMarketplaceAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const createJobWithZK = (
    jobDetailsIPFS: string,
    dataProviderShare: bigint,
    computeProviderShare: bigint,
    requiredStakeData: bigint,
    requiredStakeCompute: bigint,
    deadline: bigint,
    requiresZKProof: boolean,
    zkProofBonus: bigint,
    value: bigint
  ) => {
    writeContract({
      address,
      abi: JobMarketplaceAbi,
      functionName: "createJobWithZKRequirements",
      args: [jobDetailsIPFS, dataProviderShare, computeProviderShare, requiredStakeData, requiredStakeCompute, deadline, requiresZKProof, zkProofBonus],
      value,
    });
  };

  return { createJobWithZK, hash, error, isPending, isConfirming, isSuccess };
}

export function useApplyForJob() {
  const address = useJobMarketplaceAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const applyForJob = (jobId: `0x${string}`, providerType: number) => {
    writeContract({
      address,
      abi: JobMarketplaceAbi,
      functionName: "applyForJob",
      args: [jobId, providerType],
    });
  };

  return { applyForJob, hash, error, isPending, isConfirming, isSuccess };
}

export function useAssignProviders() {
  const address = useJobMarketplaceAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const assignProviders = (
    jobId: `0x${string}`,
    dataProvider: `0x${string}`,
    computeProvider: `0x${string}`
  ) => {
    writeContract({
      address,
      abi: JobMarketplaceAbi,
      functionName: "assignProviders",
      args: [jobId, dataProvider, computeProvider],
    });
  };

  return { assignProviders, hash, error, isPending, isConfirming, isSuccess };
}

export function useUploadDataset() {
  const address = useJobMarketplaceAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const uploadDataset = (jobId: `0x${string}`, datasetHashIPFS: string) => {
    writeContract({
      address,
      abi: JobMarketplaceAbi,
      functionName: "uploadDataset",
      args: [jobId, datasetHashIPFS],
    });
  };

  return { uploadDataset, hash, error, isPending, isConfirming, isSuccess };
}

export function useUploadDatasetWithCommitment() {
  const address = useJobMarketplaceAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const uploadDatasetWithCommitment = (
    jobId: `0x${string}`,
    datasetHashIPFS: string,
    datasetCommitment: `0x${string}`
  ) => {
    writeContract({
      address,
      abi: JobMarketplaceAbi,
      functionName: "uploadDatasetWithCommitment",
      args: [jobId, datasetHashIPFS, datasetCommitment],
    });
  };

  return { uploadDatasetWithCommitment, hash, error, isPending, isConfirming, isSuccess };
}

export function useSubmitTraining() {
  const address = useJobMarketplaceAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const submitTraining = (
    jobId: `0x${string}`,
    modelHashIPFS: string,
    metricsHashIPFS: string
  ) => {
    writeContract({
      address,
      abi: JobMarketplaceAbi,
      functionName: "submitTraining",
      args: [jobId, modelHashIPFS, metricsHashIPFS],
    });
  };

  return { submitTraining, hash, error, isPending, isConfirming, isSuccess };
}

export function useSubmitTrainingWithProof() {
  const address = useJobMarketplaceAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const submitTrainingWithProof = (
    jobId: `0x${string}`,
    modelHashIPFS: string,
    metricsHashIPFS: string,
    modelCommitment: `0x${string}`,
    metricsCommitment: `0x${string}`,
    proof: readonly [bigint, bigint, bigint, bigint, bigint, bigint, bigint, bigint],
    publicInputs: readonly bigint[]
  ) => {
    writeContract({
      address,
      abi: JobMarketplaceAbi,
      functionName: "submitTrainingWithProof",
      args: [jobId, modelHashIPFS, metricsHashIPFS, modelCommitment, metricsCommitment, proof, publicInputs],
    });
  };

  return { submitTrainingWithProof, hash, error, isPending, isConfirming, isSuccess };
}

export function useFinalizeJob() {
  const address = useJobMarketplaceAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const finalizeJob = (jobId: `0x${string}`) => {
    writeContract({
      address,
      abi: JobMarketplaceAbi,
      functionName: "finalizeJob",
      args: [jobId],
    });
  };

  return { finalizeJob, hash, error, isPending, isConfirming, isSuccess };
}

export function useCancelJob() {
  const address = useJobMarketplaceAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const cancelJob = (jobId: `0x${string}`) => {
    writeContract({
      address,
      abi: JobMarketplaceAbi,
      functionName: "cancelJob",
      args: [jobId],
    });
  };

  return { cancelJob, hash, error, isPending, isConfirming, isSuccess };
}

export function useDisputeJob() {
  const address = useJobMarketplaceAddress();
  const { data: hash, error, isPending, writeContract } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({ hash });

  const disputeJob = (jobId: `0x${string}`) => {
    writeContract({
      address,
      abi: JobMarketplaceAbi,
      functionName: "disputeJob",
      args: [jobId],
    });
  };

  return { disputeJob, hash, error, isPending, isConfirming, isSuccess };
}
