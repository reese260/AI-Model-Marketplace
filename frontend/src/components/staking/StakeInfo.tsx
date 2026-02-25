"use client";

import { Card, CardTitle } from "@/components/ui/Card";
import { Badge } from "@/components/ui/Badge";
import { Skeleton } from "@/components/ui/Skeleton";
import { formatEth, PROVIDER_TYPE_LABELS } from "@/lib/utils";
import { useGetStakeInfo } from "@/hooks/useProviderStaking";
import type { StakeInfo } from "@/lib/types";

interface StakeInfoProps {
  address: `0x${string}`;
}

export function StakeInfoCard({ address }: StakeInfoProps) {
  const { data: stakeInfoRaw, isLoading } = useGetStakeInfo(address);

  if (isLoading) {
    return (
      <Card>
        <Skeleton className="mb-2 h-6 w-32" />
        <Skeleton className="h-4 w-48" />
      </Card>
    );
  }

  const info = stakeInfoRaw as unknown as StakeInfo | undefined;

  if (!info || !info.isActive) {
    return (
      <Card>
        <CardTitle>Stake Info</CardTitle>
        <p className="mt-2 text-sm text-gray-500">No active stake</p>
      </Card>
    );
  }

  return (
    <Card>
      <div className="flex items-center justify-between">
        <CardTitle>Stake Info</CardTitle>
        <Badge variant={info.isActive ? "success" : "default"}>
          {info.isActive ? "Active" : "Inactive"}
        </Badge>
      </div>
      <div className="mt-4 grid grid-cols-2 gap-4">
        <Stat label="Total Staked" value={`${formatEth(info.amount)} MATIC`} />
        <Stat label="Locked" value={`${formatEth(info.lockedAmount)} MATIC`} />
        <Stat label="Available" value={`${formatEth(info.availableAmount)} MATIC`} />
        <Stat label="Type" value={PROVIDER_TYPE_LABELS[Number(info.providerType) as 0 | 1]} />
        <Stat label="Violations" value={String(info.violationCount)} />
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
