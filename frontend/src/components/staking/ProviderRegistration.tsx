"use client";

import { useState } from "react";
import { parseEther } from "viem";
import { useAccount } from "wagmi";
import { Card, CardTitle } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { TransactionButton } from "@/components/web3/TransactionButton";
import { Alert } from "@/components/ui/Alert";
import { useStake } from "@/hooks/useProviderStaking";
import { useRegisterProvider, useIsProviderRegistered } from "@/hooks/useReputationNFT";
import { ProviderType } from "@/lib/types";
import { MIN_DATA_PROVIDER_STAKE, MIN_COMPUTE_PROVIDER_STAKE } from "@/config/constants";
import { formatEth } from "@/lib/utils";

export function ProviderRegistration() {
  const { address } = useAccount();
  const [providerType, setProviderType] = useState<ProviderType>(ProviderType.DATA);
  const [amount, setAmount] = useState("");

  const { data: isRegistered } = useIsProviderRegistered(address);
  const { registerSelf, ...registerTxState } = useRegisterProvider();
  const { stake, ...stakeTxState } = useStake();

  const minStake =
    providerType === ProviderType.DATA
      ? MIN_DATA_PROVIDER_STAKE
      : MIN_COMPUTE_PROVIDER_STAKE;

  const handleRegister = () => {
    registerSelf();
  };

  const handleStake = () => {
    stake(providerType, parseEther(amount));
  };

  // If already registered, go straight to staking
  if (isRegistered) {
    return (
      <Card>
        <CardTitle className="mb-4">Stake as Provider</CardTitle>
        <Alert variant="success" className="mb-4">
          You are registered. Stake tokens to start participating in jobs.
        </Alert>

        <div className="space-y-4">
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Provider Type
            </label>
            <select
              value={providerType}
              onChange={(e) => setProviderType(Number(e.target.value))}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
            >
              <option value={ProviderType.DATA}>Data Provider</option>
              <option value={ProviderType.COMPUTE}>Compute Provider</option>
            </select>
          </div>

          <Input
            label={`Stake Amount (min: ${formatEth(minStake)} POL)`}
            type="number"
            step="0.01"
            placeholder={formatEth(minStake)}
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />

          <TransactionButton
            label="Stake"
            onClick={handleStake}
            disabled={!amount || parseEther(amount || "0") < minStake}
            {...stakeTxState}
          />
        </div>
      </Card>
    );
  }

  // Two-step flow: register first, then stake
  return (
    <Card>
      <CardTitle className="mb-4">Register as Provider</CardTitle>
      <Alert variant="info" className="mb-4">
        Registration is a two-step process: first register to mint your Reputation NFT, then stake
        tokens as collateral.
      </Alert>

      <div className="space-y-6">
        {/* Step 1: Register */}
        <div className="rounded-lg border border-gray-200 p-4">
          <h3 className="mb-2 text-sm font-semibold text-gray-900">
            Step 1: Register &amp; Mint Reputation NFT
          </h3>
          <p className="mb-3 text-xs text-gray-500">
            Mints a non-transferable Reputation NFT with an initial score of 500.
          </p>
          <TransactionButton
            label="Register"
            onClick={handleRegister}
            disabled={!address}
            {...registerTxState}
          />
        </div>

        {/* Step 2: Stake (disabled until registered) */}
        <div className="rounded-lg border border-gray-200 p-4 opacity-50">
          <h3 className="mb-2 text-sm font-semibold text-gray-900">
            Step 2: Stake Collateral
          </h3>
          <p className="mb-3 text-xs text-gray-500">
            Complete registration first to unlock staking.
          </p>

          <div className="space-y-3">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                Provider Type
              </label>
              <select
                disabled
                value={providerType}
                onChange={(e) => setProviderType(Number(e.target.value))}
                className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              >
                <option value={ProviderType.DATA}>Data Provider</option>
                <option value={ProviderType.COMPUTE}>Compute Provider</option>
              </select>
            </div>

            <Input
              label={`Stake Amount (min: ${formatEth(minStake)} POL)`}
              type="number"
              step="0.01"
              placeholder={formatEth(minStake)}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              disabled
            />

            <TransactionButton
              label="Stake"
              onClick={handleStake}
              disabled
              {...stakeTxState}
            />
          </div>
        </div>
      </div>
    </Card>
  );
}
