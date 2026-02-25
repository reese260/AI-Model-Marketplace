"use client";

import { useReadContracts } from "wagmi";
import { JobMarketplaceAbi } from "@/contracts/abis/JobMarketplace";
import { useContractAddress } from "@/config/contracts";
import { useJobCreatedEvents } from "@/hooks/useContractEvents";
import { JobCard } from "./JobCard";
import { Spinner } from "@/components/ui/Spinner";
import { JobStatus, type Job } from "@/lib/types";

interface JobListProps {
  filterStatus?: JobStatus;
  filterZK?: boolean;
  limit?: number;
}

export function JobList({ filterStatus, filterZK, limit }: JobListProps) {
  const address = useContractAddress("JobMarketplace");
  const { events, isLoading: eventsLoading } = useJobCreatedEvents();

  const jobIds = events.map((e) => e.jobId);

  const { data: jobsData, isLoading: jobsLoading } = useReadContracts({
    contracts: jobIds.map((jobId) => ({
      address,
      abi: JobMarketplaceAbi,
      functionName: "getJob" as const,
      args: [jobId] as const,
    })),
    query: { enabled: jobIds.length > 0 },
  });

  const isLoading = eventsLoading || jobsLoading;

  if (isLoading) {
    return (
      <div className="flex justify-center py-12">
        <Spinner size="lg" />
      </div>
    );
  }

  if (!jobsData || jobsData.length === 0) {
    return (
      <div className="py-12 text-center text-gray-500">
        No jobs found. Be the first to post a job!
      </div>
    );
  }

  let jobs = jobsData
    .map((result) => (result.status === "success" ? (result.result as unknown as Job) : null))
    .filter((job): job is Job => job !== null);

  if (filterStatus !== undefined) {
    jobs = jobs.filter((job) => job.status === filterStatus);
  }
  if (filterZK !== undefined) {
    jobs = jobs.filter((job) => job.requiresZKProof === filterZK);
  }

  // Sort by creation time, newest first
  jobs.sort((a, b) => Number(b.createdAt - a.createdAt));

  if (limit) {
    jobs = jobs.slice(0, limit);
  }

  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {jobs.map((job) => (
        <JobCard key={job.jobId} job={job} />
      ))}
    </div>
  );
}
