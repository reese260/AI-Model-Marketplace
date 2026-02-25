"use client";

import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { JobStatusBadge } from "./JobStatusBadge";
import { formatEthShort, formatAddress, timeFromNow, isDeadlinePassed } from "@/lib/utils";
import type { Job } from "@/lib/types";

interface JobCardProps {
  job: Job;
}

export function JobCard({ job }: JobCardProps) {
  const deadline = isDeadlinePassed(job.deadline);

  return (
    <Link href={`/jobs/${job.jobId}`}>
      <Card className="transition-shadow hover:shadow-md">
        <div className="flex items-start justify-between">
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-medium text-gray-900">
              {job.jobDetailsIPFS || "Untitled Job"}
            </p>
            <p className="mt-1 text-xs text-gray-500">
              by {formatAddress(job.requester)}
            </p>
          </div>
          <JobStatusBadge status={job.status} />
        </div>

        <div className="mt-4 grid grid-cols-3 gap-2 text-center">
          <div>
            <p className="text-xs text-gray-500">Payment</p>
            <p className="text-sm font-semibold text-gray-900">
              {formatEthShort(job.paymentAmount)} MATIC
            </p>
          </div>
          <div>
            <p className="text-xs text-gray-500">Deadline</p>
            <p className={`text-sm font-semibold ${deadline ? "text-red-600" : "text-gray-900"}`}>
              {timeFromNow(job.deadline)}
            </p>
          </div>
          <div>
            <p className="text-xs text-gray-500">ZK Proof</p>
            <p className="text-sm font-semibold text-gray-900">
              {job.requiresZKProof ? "Required" : "Optional"}
            </p>
          </div>
        </div>
      </Card>
    </Link>
  );
}
