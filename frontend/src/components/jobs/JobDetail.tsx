"use client";

import { Card, CardHeader, CardTitle } from "@/components/ui/Card";
import { JobStatusBadge } from "./JobStatusBadge";
import { Badge } from "@/components/ui/Badge";
import {
  formatEth,
  formatBps,
  formatAddress,
  formatTimestamp,
  timeFromNow,
  isZeroAddress,
} from "@/lib/utils";
import type { Job } from "@/lib/types";

interface JobDetailProps {
  job: Job;
}

export function JobDetail({ job }: JobDetailProps) {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-start justify-between">
          <div>
            <CardTitle>{job.jobDetailsIPFS || "Untitled Job"}</CardTitle>
            <p className="mt-1 text-sm text-gray-500">
              Posted by {formatAddress(job.requester)}
            </p>
          </div>
          <JobStatusBadge status={job.status} />
        </div>
      </CardHeader>

      <div className="grid gap-6 sm:grid-cols-2">
        <div className="space-y-3">
          <DetailRow label="Payment" value={`${formatEth(job.paymentAmount)} MATIC`} />
          <DetailRow label="Data Provider Share" value={formatBps(job.dataProviderShare)} />
          <DetailRow label="Compute Provider Share" value={formatBps(job.computeProviderShare)} />
          <DetailRow label="Required Data Stake" value={`${formatEth(job.requiredStakeData)} MATIC`} />
          <DetailRow label="Required Compute Stake" value={`${formatEth(job.requiredStakeCompute)} MATIC`} />
        </div>

        <div className="space-y-3">
          <DetailRow label="Created" value={formatTimestamp(job.createdAt)} />
          <DetailRow label="Deadline" value={`${formatTimestamp(job.deadline)} (${timeFromNow(job.deadline)})`} />
          <DetailRow
            label="Data Provider"
            value={isZeroAddress(job.dataProvider) ? "Not assigned" : formatAddress(job.dataProvider)}
          />
          <DetailRow
            label="Compute Provider"
            value={isZeroAddress(job.computeProvider) ? "Not assigned" : formatAddress(job.computeProvider)}
          />
          {job.datasetHashIPFS && (
            <DetailRow label="Dataset" value={job.datasetHashIPFS} />
          )}
        </div>
      </div>

      {job.requiresZKProof && (
        <div className="mt-4 flex items-center gap-2">
          <Badge variant="info">ZK Proof Required</Badge>
          {job.zkProofBonus > 0n && (
            <span className="text-sm text-gray-600">
              Bonus: {formatEth(job.zkProofBonus)} MATIC
            </span>
          )}
          {job.usedZKProof && <Badge variant="success">ZK Proof Used</Badge>}
        </div>
      )}
    </Card>
  );
}

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-xs font-medium text-gray-500">{label}</dt>
      <dd className="text-sm text-gray-900">{value}</dd>
    </div>
  );
}
