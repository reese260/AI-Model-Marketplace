"use client";

import { Alert } from "@/components/ui/Alert";
import { ConnectButton } from "@/components/web3/ConnectButton";
import { StakeInfoCard } from "@/components/staking/StakeInfo";
import { ReputationCard } from "@/components/reputation/ReputationCard";
import { JobList } from "@/components/jobs/JobList";
import { useUserRole } from "@/hooks/useUserRole";
import { Badge } from "@/components/ui/Badge";

export default function DashboardPage() {
  const { address, isConnected, isRegistered, isDataProvider, isComputeProvider } =
    useUserRole();

  if (!isConnected || !address) {
    return (
      <div className="mx-auto max-w-md px-4 py-16 text-center">
        <h1 className="mb-4 text-2xl font-bold text-gray-900">Dashboard</h1>
        <Alert variant="info" className="mb-4">
          Connect your wallet to view your dashboard.
        </Alert>
        <ConnectButton />
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <div className="mb-8 flex items-center gap-4">
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <div className="flex gap-2">
          {isRegistered && <Badge variant="success">Registered</Badge>}
          {isDataProvider && <Badge variant="info">Data Provider</Badge>}
          {isComputeProvider && <Badge variant="info">Compute Provider</Badge>}
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <StakeInfoCard address={address} />
        <ReputationCard address={address} />
      </div>

      <div className="mt-8">
        <h2 className="mb-4 text-xl font-bold text-gray-900">All Jobs</h2>
        <JobList />
      </div>
    </div>
  );
}
