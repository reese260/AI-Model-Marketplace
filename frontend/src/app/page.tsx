"use client";

import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { Card, CardTitle } from "@/components/ui/Card";
import { JobList } from "@/components/jobs/JobList";
import { JobStatus } from "@/lib/types";

export default function HomePage() {
  return (
    <div className="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
      {/* Hero */}
      <div className="mb-12 text-center">
        <h1 className="text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl">
          AI Model Marketplace
        </h1>
        <p className="mx-auto mt-4 max-w-2xl text-lg text-gray-600">
          Decentralized marketplace for AI model training. Post jobs, provide data or compute, and earn rewards — all secured by smart contracts on Polygon.
        </p>
        <div className="mt-8 flex items-center justify-center gap-4">
          <Link href="/jobs/create">
            <Button size="lg">Post a Job</Button>
          </Link>
          <Link href="/staking">
            <Button variant="outline" size="lg">
              Become a Provider
            </Button>
          </Link>
        </div>
      </div>

      {/* Stats */}
      <div className="mb-12 grid gap-4 sm:grid-cols-3">
        <StatCard title="How it Works" description="Post a training job with payment. Data and compute providers apply, get assigned, and deliver results verified on-chain." />
        <StatCard title="ZK Verification" description="Optional zero-knowledge proofs provide instant verification of training results without revealing sensitive data." />
        <StatCard title="Reputation System" description="On-chain reputation NFTs track provider performance with EMA-based scoring and confidence metrics." />
      </div>

      {/* Recent Jobs */}
      <div>
        <div className="mb-6 flex items-center justify-between">
          <h2 className="text-2xl font-bold text-gray-900">Recent Open Jobs</h2>
          <Link href="/jobs">
            <Button variant="ghost">View All</Button>
          </Link>
        </div>
        <JobList filterStatus={JobStatus.OPEN} limit={6} />
      </div>
    </div>
  );
}

function StatCard({ title, description }: { title: string; description: string }) {
  return (
    <Card>
      <CardTitle>{title}</CardTitle>
      <p className="mt-2 text-sm text-gray-600">{description}</p>
    </Card>
  );
}
