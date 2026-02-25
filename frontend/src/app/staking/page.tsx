"use client";

import { Alert } from "@/components/ui/Alert";
import { ConnectButton } from "@/components/web3/ConnectButton";
import { ProviderRegistration } from "@/components/staking/ProviderRegistration";
import { StakeInfoCard } from "@/components/staking/StakeInfo";
import { StakeForm } from "@/components/staking/StakeForm";
import { useUserRole } from "@/hooks/useUserRole";
import { Spinner } from "@/components/ui/Spinner";

export default function StakingPage() {
  const { address, isConnected, hasStake, isLoading } = useUserRole();

  if (!isConnected || !address) {
    return (
      <div className="mx-auto max-w-md px-4 py-16 text-center">
        <h1 className="mb-4 text-2xl font-bold text-gray-900">Provider Staking</h1>
        <Alert variant="info" className="mb-4">
          Connect your wallet to manage staking.
        </Alert>
        <ConnectButton />
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="flex justify-center py-16">
        <Spinner size="lg" />
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <h1 className="mb-8 text-3xl font-bold text-gray-900">Provider Staking</h1>

      {!hasStake ? (
        <div className="mx-auto max-w-lg">
          <ProviderRegistration />
        </div>
      ) : (
        <div className="grid gap-6 lg:grid-cols-2">
          <StakeInfoCard address={address} />
          <div className="space-y-6">
            <StakeForm mode="deposit" />
            <StakeForm mode="withdraw" />
          </div>
        </div>
      )}
    </div>
  );
}
