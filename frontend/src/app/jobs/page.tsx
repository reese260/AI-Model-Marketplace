"use client";

import { useState } from "react";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { JobList } from "@/components/jobs/JobList";
import { JobStatus } from "@/lib/types";

const STATUS_FILTERS = [
  { label: "All", value: undefined },
  { label: "Open", value: JobStatus.OPEN },
  { label: "In Progress", value: JobStatus.IN_PROGRESS },
  { label: "Submitted", value: JobStatus.SUBMITTED },
  { label: "Completed", value: JobStatus.COMPLETED },
] as const;

export default function JobsPage() {
  const [statusFilter, setStatusFilter] = useState<JobStatus | undefined>(undefined);
  const [zkFilter, setZkFilter] = useState<boolean | undefined>(undefined);

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <div className="mb-8 flex items-center justify-between">
        <h1 className="text-3xl font-bold text-gray-900">Browse Jobs</h1>
        <Link href="/jobs/create">
          <Button>Create Job</Button>
        </Link>
      </div>

      {/* Filters */}
      <div className="mb-6 flex flex-wrap items-center gap-2">
        {STATUS_FILTERS.map((f) => (
          <button
            key={f.label}
            onClick={() => setStatusFilter(f.value)}
            className={`rounded-full px-3 py-1.5 text-sm font-medium transition-colors ${
              statusFilter === f.value
                ? "bg-indigo-100 text-indigo-700"
                : "bg-gray-100 text-gray-600 hover:bg-gray-200"
            }`}
          >
            {f.label}
          </button>
        ))}
        <span className="mx-2 text-gray-300">|</span>
        <button
          onClick={() => setZkFilter(zkFilter === true ? undefined : true)}
          className={`rounded-full px-3 py-1.5 text-sm font-medium transition-colors ${
            zkFilter === true
              ? "bg-indigo-100 text-indigo-700"
              : "bg-gray-100 text-gray-600 hover:bg-gray-200"
          }`}
        >
          ZK Required
        </button>
      </div>

      <JobList filterStatus={statusFilter} filterZK={zkFilter} />
    </div>
  );
}
