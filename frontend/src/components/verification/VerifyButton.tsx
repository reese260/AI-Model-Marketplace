"use client";

import { TransactionButton } from "@/components/web3/TransactionButton";
import { useVerifyTraining, useIsInChallengePeriod } from "@/hooks/useTrainingVerification";

interface VerifyButtonProps {
  jobId: `0x${string}`;
}

export function VerifyButton({ jobId }: VerifyButtonProps) {
  const { verifyTraining, ...txState } = useVerifyTraining();
  const { data: inChallengePeriod } = useIsInChallengePeriod(jobId);

  return (
    <TransactionButton
      label="Verify Training"
      onClick={() => verifyTraining(jobId)}
      disabled={inChallengePeriod === true}
      {...txState}
    />
  );
}
