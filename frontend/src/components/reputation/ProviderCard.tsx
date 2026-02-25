"use client";

import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { ReputationBadge } from "./ReputationBadge";
import { Badge } from "@/components/ui/Badge";
import { formatAddress, PROVIDER_TYPE_LABELS } from "@/lib/utils";

interface ProviderCardProps {
  address: `0x${string}`;
  providerType: number;
  score: bigint;
  jobsCompleted: bigint;
  isActive: boolean;
}

export function ProviderCard({
  address,
  providerType,
  score,
  jobsCompleted,
  isActive,
}: ProviderCardProps) {
  return (
    <Link href={`/providers/${address}`}>
      <Card className="transition-shadow hover:shadow-md">
        <div className="flex items-start justify-between">
          <div>
            <p className="font-medium text-gray-900">{formatAddress(address)}</p>
            <p className="mt-1 text-xs text-gray-500">
              {PROVIDER_TYPE_LABELS[providerType as 0 | 1]}
            </p>
          </div>
          <Badge variant={isActive ? "success" : "default"}>
            {isActive ? "Active" : "Inactive"}
          </Badge>
        </div>
        <div className="mt-3 flex items-center justify-between">
          <ReputationBadge score={score} />
          <span className="text-xs text-gray-500">
            {String(jobsCompleted)} jobs completed
          </span>
        </div>
      </Card>
    </Link>
  );
}
