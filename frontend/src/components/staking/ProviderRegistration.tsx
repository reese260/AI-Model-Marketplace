"use client";

import { useState } from "react";
import { parseEther } from "viem";
import { Card, CardTitle } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { TransactionButton } from "@/components/web3/TransactionButton";
import { Alert } from "@/components/ui/Alert";
import { useStake } from "@/hooks/useProviderStaking";
import { ProviderType } from "@/lib/types";
import { MIN_DATA_PROVIDER_STAKE, MIN_COMPUTE_PROVIDER_STAKE } from "@/config/constants";
import { formatEth } from "@/lib/utils";

export function ProviderRegistration() {
  const [providerType, setProviderType] = useState<ProviderType>(ProviderType.DATA);
  const [amount, setAmount] = useState("");
  const { stake, ...txState } = useStake();

  const minStake =
    providerType === ProviderType.DATA
      ? MIN_DATA_PROVIDER_STAKE
      : MIN_COMPUTE_PROVIDER_STAKE;

  const handleSubmit = () => {
    stake(providerType, parseEther(amount));
  };

  return (
    <Card>
      <CardTitle className="mb-4">Register as Provider</CardTitle>
      <Alert variant="info" className="mb-4">
        Registration requires an initial stake. This locks your tokens as collateral for job participation.
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
          label={`Stake Amount (min: ${formatEth(minStake)} MATIC)`}
          type="number"
          step="0.01"
          placeholder={formatEth(minStake)}
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
        />

        <TransactionButton
          label="Register & Stake"
          onClick={handleSubmit}
          disabled={!amount || parseEther(amount || "0") < minStake}
          {...txState}
        />
      </div>
    </Card>
  );
}
