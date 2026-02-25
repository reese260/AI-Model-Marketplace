"use client";

import { useAccount } from "wagmi";
import { CreateJobForm } from "@/components/jobs/CreateJobForm";
import { Alert } from "@/components/ui/Alert";
import { ConnectButton } from "@/components/web3/ConnectButton";

export default function CreateJobPage() {
  const { isConnected } = useAccount();

  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <h1 className="mb-8 text-3xl font-bold text-gray-900">Create Training Job</h1>

      {!isConnected ? (
        <div className="mx-auto max-w-md text-center">
          <Alert variant="info" className="mb-4">
            Connect your wallet to create a job.
          </Alert>
          <ConnectButton />
        </div>
      ) : (
        <CreateJobForm />
      )}
    </div>
  );
}
