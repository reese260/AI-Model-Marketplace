"use client";

import { useState } from "react";
import { parseEther } from "viem";
import { Button } from "@/components/ui/Button";
import { Input } from "@/components/ui/Input";
import { Card, CardTitle } from "@/components/ui/Card";
import { Alert } from "@/components/ui/Alert";
import { TransactionButton } from "@/components/web3/TransactionButton";
import { useCreateJob, useCreateJobWithZK } from "@/hooks/useJobMarketplace";
import { PLATFORM_FEE_BPS } from "@/config/constants";

const STEPS = ["Details", "Payment", "Requirements", "ZK Options", "Review"] as const;

export function CreateJobForm() {
  const [step, setStep] = useState(0);
  const [form, setForm] = useState({
    jobDetailsIPFS: "",
    paymentAmount: "",
    dataProviderShare: "2000",
    computeProviderShare: "7000",
    requiredStakeData: "0.1",
    requiredStakeCompute: "0.5",
    deadlineDays: "7",
    requiresZKProof: false,
    zkProofBonus: "0",
  });

  const { createJob, ...createTx } = useCreateJob();
  const { createJobWithZK, ...createZKTx } = useCreateJobWithZK();

  const tx = form.requiresZKProof ? createZKTx : createTx;

  const update = (key: string, value: string | boolean) =>
    setForm((prev) => ({ ...prev, [key]: value }));

  const shareSum = Number(form.dataProviderShare) + Number(form.computeProviderShare);
  const shareValid = shareSum + PLATFORM_FEE_BPS === 10000;

  const handleSubmit = () => {
    const deadline = BigInt(Math.floor(Date.now() / 1000) + Number(form.deadlineDays) * 86400);
    const value = parseEther(form.paymentAmount);

    if (form.requiresZKProof) {
      createJobWithZK(
        form.jobDetailsIPFS,
        BigInt(form.dataProviderShare),
        BigInt(form.computeProviderShare),
        parseEther(form.requiredStakeData),
        parseEther(form.requiredStakeCompute),
        deadline,
        true,
        parseEther(form.zkProofBonus),
        value + parseEther(form.zkProofBonus)
      );
    } else {
      createJob(
        form.jobDetailsIPFS,
        BigInt(form.dataProviderShare),
        BigInt(form.computeProviderShare),
        parseEther(form.requiredStakeData),
        parseEther(form.requiredStakeCompute),
        deadline,
        value
      );
    }
  };

  return (
    <Card className="mx-auto max-w-2xl">
      <CardTitle className="mb-6">Create Training Job</CardTitle>

      {/* Step indicator */}
      <div className="mb-8 flex items-center justify-between">
        {STEPS.map((s, i) => (
          <div key={s} className="flex items-center gap-2">
            <div
              className={`flex h-8 w-8 items-center justify-center rounded-full text-xs font-medium ${
                i <= step ? "bg-indigo-600 text-white" : "bg-gray-200 text-gray-600"
              }`}
            >
              {i + 1}
            </div>
            <span className="hidden text-xs sm:inline">{s}</span>
          </div>
        ))}
      </div>

      {/* Step 0: Details */}
      {step === 0 && (
        <div className="space-y-4">
          <Input
            label="Job Details (IPFS Hash)"
            placeholder="QmXyz... or description"
            value={form.jobDetailsIPFS}
            onChange={(e) => update("jobDetailsIPFS", e.target.value)}
          />
        </div>
      )}

      {/* Step 1: Payment */}
      {step === 1 && (
        <div className="space-y-4">
          <Input
            label="Payment Amount (MATIC)"
            type="number"
            step="0.01"
            placeholder="1.0"
            value={form.paymentAmount}
            onChange={(e) => update("paymentAmount", e.target.value)}
          />
          <Input
            label="Data Provider Share (BPS)"
            type="number"
            placeholder="2000"
            value={form.dataProviderShare}
            onChange={(e) => update("dataProviderShare", e.target.value)}
          />
          <Input
            label="Compute Provider Share (BPS)"
            type="number"
            placeholder="7000"
            value={form.computeProviderShare}
            onChange={(e) => update("computeProviderShare", e.target.value)}
          />
          <p className="text-xs text-gray-500">
            Platform fee: {PLATFORM_FEE_BPS / 100}%. Shares must sum to {(10000 - PLATFORM_FEE_BPS) / 100}%.
          </p>
          {!shareValid && (
            <Alert variant="warning">
              Shares ({shareSum} BPS) + platform fee ({PLATFORM_FEE_BPS} BPS) must equal 10000 BPS.
            </Alert>
          )}
        </div>
      )}

      {/* Step 2: Requirements */}
      {step === 2 && (
        <div className="space-y-4">
          <Input
            label="Required Data Provider Stake (MATIC)"
            type="number"
            step="0.01"
            value={form.requiredStakeData}
            onChange={(e) => update("requiredStakeData", e.target.value)}
          />
          <Input
            label="Required Compute Provider Stake (MATIC)"
            type="number"
            step="0.01"
            value={form.requiredStakeCompute}
            onChange={(e) => update("requiredStakeCompute", e.target.value)}
          />
          <Input
            label="Deadline (days from now)"
            type="number"
            value={form.deadlineDays}
            onChange={(e) => update("deadlineDays", e.target.value)}
          />
        </div>
      )}

      {/* Step 3: ZK Options */}
      {step === 3 && (
        <div className="space-y-4">
          <label className="flex items-center gap-3">
            <input
              type="checkbox"
              checked={form.requiresZKProof}
              onChange={(e) => update("requiresZKProof", e.target.checked)}
              className="h-4 w-4 rounded border-gray-300 text-indigo-600"
            />
            <span className="text-sm font-medium text-gray-700">Require ZK Proof</span>
          </label>
          {form.requiresZKProof && (
            <Input
              label="ZK Proof Bonus (MATIC)"
              type="number"
              step="0.01"
              placeholder="0.1"
              value={form.zkProofBonus}
              onChange={(e) => update("zkProofBonus", e.target.value)}
            />
          )}
        </div>
      )}

      {/* Step 4: Review */}
      {step === 4 && (
        <div className="space-y-3 text-sm">
          <ReviewRow label="Job Details" value={form.jobDetailsIPFS || "(empty)"} />
          <ReviewRow label="Payment" value={`${form.paymentAmount || "0"} MATIC`} />
          <ReviewRow label="Data Share" value={`${Number(form.dataProviderShare) / 100}%`} />
          <ReviewRow label="Compute Share" value={`${Number(form.computeProviderShare) / 100}%`} />
          <ReviewRow label="Req. Data Stake" value={`${form.requiredStakeData} MATIC`} />
          <ReviewRow label="Req. Compute Stake" value={`${form.requiredStakeCompute} MATIC`} />
          <ReviewRow label="Deadline" value={`${form.deadlineDays} days`} />
          <ReviewRow label="ZK Proof" value={form.requiresZKProof ? `Required (${form.zkProofBonus} MATIC bonus)` : "Optional"} />

          <div className="pt-4">
            <TransactionButton
              label="Create Job"
              onClick={handleSubmit}
              disabled={!form.jobDetailsIPFS || !form.paymentAmount || !shareValid}
              isPending={tx.isPending}
              isConfirming={tx.isConfirming}
              isSuccess={tx.isSuccess}
              error={tx.error}
              hash={tx.hash}
            />
          </div>
        </div>
      )}

      {/* Navigation */}
      {step < 4 && (
        <div className="mt-6 flex justify-between">
          <Button
            variant="ghost"
            onClick={() => setStep((s) => s - 1)}
            disabled={step === 0}
          >
            Back
          </Button>
          <Button onClick={() => setStep((s) => s + 1)}>
            Next
          </Button>
        </div>
      )}
      {step === 4 && !tx.isSuccess && (
        <div className="mt-4">
          <Button variant="ghost" onClick={() => setStep(0)}>
            Start Over
          </Button>
        </div>
      )}
    </Card>
  );
}

function ReviewRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between">
      <span className="text-gray-500">{label}</span>
      <span className="font-medium text-gray-900">{value}</span>
    </div>
  );
}
