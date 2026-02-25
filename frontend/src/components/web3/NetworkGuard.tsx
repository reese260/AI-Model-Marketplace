"use client";

import { useAccount, useChainId, useSwitchChain } from "wagmi";
import { polygonAmoy } from "wagmi/chains";
import { Alert } from "@/components/ui/Alert";
import { Button } from "@/components/ui/Button";
import { SUPPORTED_CHAIN_IDS } from "@/config/constants";

export function NetworkGuard({ children }: { children: React.ReactNode }) {
  const { isConnected } = useAccount();
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();

  if (!isConnected) return <>{children}</>;

  const isSupported = SUPPORTED_CHAIN_IDS.includes(chainId as 80002 | 137);
  if (isSupported) return <>{children}</>;

  return (
    <div className="mx-auto max-w-md py-16 text-center">
      <Alert variant="warning" className="mb-4">
        You are connected to an unsupported network. Please switch to Polygon Amoy or Polygon Mainnet.
      </Alert>
      <Button onClick={() => switchChain({ chainId: polygonAmoy.id })}>
        Switch to Amoy Testnet
      </Button>
    </div>
  );
}
