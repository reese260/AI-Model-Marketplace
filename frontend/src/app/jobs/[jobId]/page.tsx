"use client";

import { useParams } from "next/navigation";
import { useGetJob, useGetJobApplicants } from "@/hooks/useJobMarketplace";
import { JobDetail } from "@/components/jobs/JobDetail";
import { JobActions } from "@/components/jobs/JobActions";
import { VerificationStatusCard } from "@/components/verification/VerificationStatus";
import { ChallengeForm } from "@/components/verification/ChallengeForm";
import { VerifyButton } from "@/components/verification/VerifyButton";
import { Spinner } from "@/components/ui/Spinner";
import { Alert } from "@/components/ui/Alert";
import { Card, CardTitle } from "@/components/ui/Card";
import { formatAddress } from "@/lib/utils";
import { JobStatus, type Job } from "@/lib/types";

export default function JobDetailPage() {
  const params = useParams();
  const jobId = params.jobId as `0x${string}`;

  const { data: jobData, isLoading, error } = useGetJob(jobId);
  const { data: applicants } = useGetJobApplicants(jobId);

  if (isLoading) {
    return (
      <div className="flex justify-center py-16">
        <Spinner size="lg" />
      </div>
    );
  }

  if (error || !jobData) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-16">
        <Alert variant="error">
          {error?.message || "Job not found"}
        </Alert>
      </div>
    );
  }

  const job = jobData as unknown as Job;

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <div className="grid gap-6 lg:grid-cols-3">
        {/* Main content */}
        <div className="space-y-6 lg:col-span-2">
          <JobDetail job={job} />

          {/* Applicants */}
          {applicants && (
            <Card>
              <CardTitle className="mb-4">Applicants</CardTitle>
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <p className="mb-2 text-sm font-medium text-gray-500">
                    Data Providers ({(applicants[0] as `0x${string}`[])?.length || 0})
                  </p>
                  {(applicants[0] as `0x${string}`[])?.map((addr) => (
                    <p key={addr} className="text-sm text-gray-900">
                      {formatAddress(addr)}
                    </p>
                  ))}
                  {(applicants[0] as `0x${string}`[])?.length === 0 && (
                    <p className="text-sm text-gray-400">None yet</p>
                  )}
                </div>
                <div>
                  <p className="mb-2 text-sm font-medium text-gray-500">
                    Compute Providers ({(applicants[1] as `0x${string}`[])?.length || 0})
                  </p>
                  {(applicants[1] as `0x${string}`[])?.map((addr) => (
                    <p key={addr} className="text-sm text-gray-900">
                      {formatAddress(addr)}
                    </p>
                  ))}
                  {(applicants[1] as `0x${string}`[])?.length === 0 && (
                    <p className="text-sm text-gray-400">None yet</p>
                  )}
                </div>
              </div>
            </Card>
          )}

          {/* Verification info */}
          {(job.status === JobStatus.SUBMITTED ||
            job.status === JobStatus.COMPLETED ||
            job.status === JobStatus.DISPUTED) && (
            <>
              <VerificationStatusCard jobId={jobId} />
              {job.status === JobStatus.SUBMITTED && (
                <div className="grid gap-4 sm:grid-cols-2">
                  <ChallengeForm jobId={jobId} />
                  <Card>
                    <CardTitle className="mb-4">Verify</CardTitle>
                    <p className="mb-3 text-sm text-gray-500">
                      After the challenge period ends, anyone can verify the training.
                    </p>
                    <VerifyButton jobId={jobId} />
                  </Card>
                </div>
              )}
            </>
          )}
        </div>

        {/* Sidebar: Actions */}
        <div>
          <JobActions job={job} />
        </div>
      </div>
    </div>
  );
}
