"use client";

import { Card, CardTitle } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";
import { Skeleton } from "@/components/ui/Skeleton";
import { useGetSubmission, useIsInChallengePeriod } from "@/hooks/useTrainingVerification";
import {
  VERIFICATION_STATUS_LABELS,
  VERIFICATION_STATUS_COLORS,
  formatTimestamp,
  formatAddress,
  timeFromNow,
} from "@/lib/utils";
import { VerificationStatus as VStatus, type TrainingSubmission } from "@/lib/types";

interface VerificationStatusProps {
  jobId: `0x${string}`;
}

export function VerificationStatusCard({ jobId }: VerificationStatusProps) {
  const { data: submission, isLoading } = useGetSubmission(jobId);
  const { data: inChallengePeriod } = useIsInChallengePeriod(jobId);

  if (isLoading) {
    return (
      <Card>
        <Skeleton className="mb-2 h-6 w-32" />
        <Skeleton className="h-16 w-full" />
      </Card>
    );
  }

  if (!submission) {
    return (
      <Card>
        <CardTitle>Verification</CardTitle>
        <p className="mt-2 text-sm text-gray-500">No training submitted yet</p>
      </Card>
    );
  }

  const sub = submission as unknown as TrainingSubmission;
  const status = Number(sub.status) as VStatus;

  return (
    <Card>
      <div className="flex items-center justify-between">
        <CardTitle>Verification</CardTitle>
        <span
          className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${VERIFICATION_STATUS_COLORS[status]}`}
        >
          {VERIFICATION_STATUS_LABELS[status]}
        </span>
      </div>
      <div className="mt-4 space-y-2 text-sm">
        <p>
          <span className="text-gray-500">Compute Provider:</span>{" "}
          {formatAddress(sub.computeProvider)}
        </p>
        <p>
          <span className="text-gray-500">Submitted:</span>{" "}
          {formatTimestamp(sub.submissionTime)}
        </p>
        <p>
          <span className="text-gray-500">Challenge Deadline:</span>{" "}
          {formatTimestamp(sub.challengeDeadline)} ({timeFromNow(sub.challengeDeadline)})
        </p>
        {inChallengePeriod && (
          <Badge variant="warning">In Challenge Period</Badge>
        )}
        {sub.hasZKProof && <Badge variant="info">Has ZK Proof</Badge>}
      </div>
    </Card>
  );
}
