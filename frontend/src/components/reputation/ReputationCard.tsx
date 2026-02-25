"use client";

import { Card, CardTitle } from "@/components/ui/Card";
import { Skeleton } from "@/components/ui/Skeleton";
import { ReputationBadge } from "./ReputationBadge";
import { useGetProviderReputation, useGetConfidenceScore } from "@/hooks/useReputationNFT";
import { formatEth, formatTimestamp } from "@/lib/utils";

interface ReputationCardProps {
  address: `0x${string}`;
}

export function ReputationCard({ address }: ReputationCardProps) {
  const { data: reputation, isLoading: repLoading } = useGetProviderReputation(address);
  const { data: confidence, isLoading: confLoading } = useGetConfidenceScore(address);

  if (repLoading || confLoading) {
    return (
      <Card>
        <Skeleton className="mb-2 h-6 w-32" />
        <Skeleton className="h-20 w-full" />
      </Card>
    );
  }

  if (!reputation) {
    return (
      <Card>
        <CardTitle>Reputation</CardTitle>
        <p className="mt-2 text-sm text-gray-500">Not registered</p>
      </Card>
    );
  }

  // wagmi returns struct as object with named properties
  const rep = reputation as unknown as {
    score: bigint;
    totalJobsCompleted: bigint;
    totalJobsFailed: bigint;
    totalStakeSlashed: bigint;
    registrationTime: bigint;
    lastUpdateTime: bigint;
    zkProofsSubmitted: bigint;
  };

  return (
    <Card>
      <div className="flex items-center justify-between">
        <CardTitle>Reputation</CardTitle>
        <ReputationBadge score={rep.score} />
      </div>
      <div className="mt-4 grid grid-cols-2 gap-4">
        <Stat label="Jobs Completed" value={String(rep.totalJobsCompleted)} />
        <Stat label="Jobs Failed" value={String(rep.totalJobsFailed)} />
        <Stat label="Stake Slashed" value={`${formatEth(rep.totalStakeSlashed)} MATIC`} />
        <Stat label="ZK Proofs" value={String(rep.zkProofsSubmitted)} />
        <Stat label="Registered" value={formatTimestamp(rep.registrationTime)} />
        {confidence !== undefined && (
          <Stat label="Confidence" value={`${Number(confidence)}%`} />
        )}
      </div>
    </Card>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-xs text-gray-500">{label}</p>
      <p className="text-sm font-semibold text-gray-900">{value}</p>
    </div>
  );
}
