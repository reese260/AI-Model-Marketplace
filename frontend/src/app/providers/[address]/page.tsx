"use client";

import { useParams } from "next/navigation";
import { ReputationCard } from "@/components/reputation/ReputationCard";
import { StakeInfoCard } from "@/components/staking/StakeInfo";
import { formatAddress } from "@/lib/utils";
import { useIsProviderRegistered } from "@/hooks/useReputationNFT";
import { Alert } from "@/components/ui/Alert";
import { Spinner } from "@/components/ui/Spinner";

export default function ProviderProfilePage() {
  const params = useParams();
  const address = params.address as `0x${string}`;

  const { data: isRegistered, isLoading } = useIsProviderRegistered(address);

  if (isLoading) {
    return (
      <div className="flex justify-center py-16">
        <Spinner size="lg" />
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <h1 className="mb-2 text-3xl font-bold text-gray-900">
        Provider Profile
      </h1>
      <p className="mb-8 text-sm text-gray-500">{address}</p>

      {!isRegistered ? (
        <Alert variant="warning">
          This address ({formatAddress(address)}) is not a registered provider.
        </Alert>
      ) : (
        <div className="grid gap-6 lg:grid-cols-2">
          <ReputationCard address={address} />
          <StakeInfoCard address={address} />
        </div>
      )}
    </div>
  );
}
