"use client";

import { useState } from "react";
import { Card, CardTitle } from "@/components/ui/Card";
import { Input } from "@/components/ui/Input";
import { TransactionButton } from "@/components/web3/TransactionButton";
import { useChallengeTraining } from "@/hooks/useTrainingVerification";

interface ChallengeFormProps {
  jobId: `0x${string}`;
}

export function ChallengeForm({ jobId }: ChallengeFormProps) {
  const [reason, setReason] = useState("");
  const { challengeTraining, ...txState } = useChallengeTraining();

  return (
    <Card>
      <CardTitle className="mb-4">Challenge Training</CardTitle>
      <div className="space-y-3">
        <Input
          label="Reason for Challenge"
          placeholder="Describe the issue..."
          value={reason}
          onChange={(e) => setReason(e.target.value)}
        />
        <TransactionButton
          label="Submit Challenge"
          onClick={() => challengeTraining(jobId, reason)}
          disabled={!reason}
          variant="danger"
          {...txState}
        />
      </div>
    </Card>
  );
}
