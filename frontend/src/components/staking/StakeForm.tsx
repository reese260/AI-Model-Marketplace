"use client";

import { useState } from "react";
import { parseEther } from "viem";
import { Card, CardTitle } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { TransactionButton } from "@/components/web3/TransactionButton";
import { useStake, useUnstake } from "@/hooks/useProviderStaking";

interface StakeFormProps {
  mode: "deposit" | "withdraw";
}

export function StakeForm({ mode }: StakeFormProps) {
  const [amount, setAmount] = useState("");
  const { stake, ...stakeTx } = useStake();
  const { unstake, ...unstakeTx } = useUnstake();

  const tx = mode === "deposit" ? stakeTx : unstakeTx;

  const handleSubmit = () => {
    const value = parseEther(amount);
    if (mode === "deposit") {
      stake(0, value); // providerType is ignored for additional deposits
    } else {
      unstake(value);
    }
  };

  return (
    <Card>
      <CardTitle className="mb-4">
        {mode === "deposit" ? "Deposit Stake" : "Withdraw Stake"}
      </CardTitle>
      <div className="space-y-3">
        <Input
          label="Amount (MATIC)"
          type="number"
          step="0.01"
          placeholder="0.1"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
        />
        <TransactionButton
          label={mode === "deposit" ? "Deposit" : "Withdraw"}
          onClick={handleSubmit}
          disabled={!amount || Number(amount) <= 0}
          isPending={tx.isPending}
          isConfirming={tx.isConfirming}
          isSuccess={tx.isSuccess}
          error={tx.error}
          hash={tx.hash}
        />
      </div>
    </Card>
  );
}
