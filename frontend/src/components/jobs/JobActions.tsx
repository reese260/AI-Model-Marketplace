"use client";

import { useState } from "react";
import { useAccount } from "wagmi";
import { TransactionButton } from "@/components/web3/TransactionButton";
import { Input } from "@/components/ui/Input";
import { Card, CardTitle } from "@/components/ui/Card";
import {
  useApplyForJob,
  useAssignProviders,
  useUploadDataset,
  useSubmitTraining,
  useFinalizeJob,
  useCancelJob,
  useDisputeJob,
} from "@/hooks/useJobMarketplace";
import { JobStatus, ProviderType, type Job } from "@/lib/types";

interface JobActionsProps {
  job: Job;
}

export function JobActions({ job }: JobActionsProps) {
  const { address } = useAccount();
  if (!address) return null;

  const isRequester = address.toLowerCase() === job.requester.toLowerCase();
  const isDataProv = address.toLowerCase() === job.dataProvider.toLowerCase();
  const isComputeProv = address.toLowerCase() === job.computeProvider.toLowerCase();

  return (
    <Card>
      <CardTitle className="mb-4">Actions</CardTitle>

      {job.status === JobStatus.OPEN && !isRequester && (
        <ApplyAction jobId={job.jobId} />
      )}

      {job.status === JobStatus.OPEN && isRequester && (
        <>
          <AssignAction jobId={job.jobId} />
          <div className="mt-3">
            <CancelAction jobId={job.jobId} />
          </div>
        </>
      )}

      {job.status === JobStatus.IN_PROGRESS && isDataProv && !job.datasetHashIPFS && (
        <UploadDatasetAction jobId={job.jobId} />
      )}

      {job.status === JobStatus.IN_PROGRESS && isComputeProv && (
        <SubmitTrainingAction jobId={job.jobId} />
      )}

      {job.status === JobStatus.SUBMITTED && isRequester && (
        <FinalizeAction jobId={job.jobId} />
      )}

      {job.status === JobStatus.SUBMITTED && !isRequester && (
        <DisputeAction jobId={job.jobId} />
      )}

      {(job.status === JobStatus.OPEN || job.status === JobStatus.IN_PROGRESS) && isRequester && (
        <div className="mt-3">
          <CancelAction jobId={job.jobId} />
        </div>
      )}
    </Card>
  );
}

function ApplyAction({ jobId }: { jobId: `0x${string}` }) {
  const [providerType, setProviderType] = useState(ProviderType.DATA);
  const { applyForJob, ...txState } = useApplyForJob();

  return (
    <div>
      <select
        value={providerType}
        onChange={(e) => setProviderType(Number(e.target.value))}
        className="mb-3 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
      >
        <option value={ProviderType.DATA}>Data Provider</option>
        <option value={ProviderType.COMPUTE}>Compute Provider</option>
      </select>
      <TransactionButton
        label="Apply for Job"
        onClick={() => applyForJob(jobId, providerType)}
        {...txState}
      />
    </div>
  );
}

function AssignAction({ jobId }: { jobId: `0x${string}` }) {
  const [dataProv, setDataProv] = useState("");
  const [computeProv, setComputeProv] = useState("");
  const { assignProviders, ...txState } = useAssignProviders();

  return (
    <div className="space-y-3">
      <Input
        label="Data Provider Address"
        placeholder="0x..."
        value={dataProv}
        onChange={(e) => setDataProv(e.target.value)}
      />
      <Input
        label="Compute Provider Address"
        placeholder="0x..."
        value={computeProv}
        onChange={(e) => setComputeProv(e.target.value)}
      />
      <TransactionButton
        label="Assign Providers"
        onClick={() =>
          assignProviders(jobId, dataProv as `0x${string}`, computeProv as `0x${string}`)
        }
        disabled={!dataProv || !computeProv}
        {...txState}
      />
    </div>
  );
}

function UploadDatasetAction({ jobId }: { jobId: `0x${string}` }) {
  const [ipfsHash, setIpfsHash] = useState("");
  const { uploadDataset, ...txState } = useUploadDataset();

  return (
    <div className="space-y-3">
      <Input
        label="Dataset IPFS Hash"
        placeholder="QmXyz..."
        value={ipfsHash}
        onChange={(e) => setIpfsHash(e.target.value)}
      />
      <TransactionButton
        label="Upload Dataset"
        onClick={() => uploadDataset(jobId, ipfsHash)}
        disabled={!ipfsHash}
        {...txState}
      />
    </div>
  );
}

function SubmitTrainingAction({ jobId }: { jobId: `0x${string}` }) {
  const [modelHash, setModelHash] = useState("");
  const [metricsHash, setMetricsHash] = useState("");
  const { submitTraining, ...txState } = useSubmitTraining();

  return (
    <div className="space-y-3">
      <Input
        label="Model IPFS Hash"
        placeholder="QmXyz..."
        value={modelHash}
        onChange={(e) => setModelHash(e.target.value)}
      />
      <Input
        label="Metrics IPFS Hash"
        placeholder="QmXyz..."
        value={metricsHash}
        onChange={(e) => setMetricsHash(e.target.value)}
      />
      <TransactionButton
        label="Submit Training"
        onClick={() => submitTraining(jobId, modelHash, metricsHash)}
        disabled={!modelHash || !metricsHash}
        {...txState}
      />
    </div>
  );
}

function FinalizeAction({ jobId }: { jobId: `0x${string}` }) {
  const { finalizeJob, ...txState } = useFinalizeJob();
  return (
    <TransactionButton
      label="Finalize Job"
      onClick={() => finalizeJob(jobId)}
      {...txState}
    />
  );
}

function CancelAction({ jobId }: { jobId: `0x${string}` }) {
  const { cancelJob, ...txState } = useCancelJob();
  return (
    <TransactionButton
      label="Cancel Job"
      onClick={() => cancelJob(jobId)}
      variant="danger"
      {...txState}
    />
  );
}

function DisputeAction({ jobId }: { jobId: `0x${string}` }) {
  const { disputeJob, ...txState } = useDisputeJob();
  return (
    <TransactionButton
      label="Dispute Job"
      onClick={() => disputeJob(jobId)}
      variant="danger"
      {...txState}
    />
  );
}
