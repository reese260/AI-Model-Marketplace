"use client";

import { Button } from "@/components/ui/Button";
import { Spinner } from "@/components/ui/Spinner";
import { getExplorerUrl } from "@/lib/utils";
import { useChainId } from "wagmi";

interface TransactionButtonProps {
  label: string;
  onClick: () => void;
  isPending: boolean;
  isConfirming: boolean;
  isSuccess: boolean;
  error: Error | null;
  hash?: `0x${string}`;
  disabled?: boolean;
  variant?: "primary" | "secondary" | "danger";
  className?: string;
}

export function TransactionButton({
  label,
  onClick,
  isPending,
  isConfirming,
  isSuccess,
  error,
  hash,
  disabled,
  variant = "primary",
  className,
}: TransactionButtonProps) {
  const chainId = useChainId();

  return (
    <div className={className}>
      <Button
        variant={variant}
        onClick={onClick}
        disabled={disabled || isPending || isConfirming}
        className="w-full"
      >
        {isPending && (
          <span className="flex items-center gap-2">
            <Spinner size="sm" className="text-white" />
            Confirm in wallet...
          </span>
        )}
        {isConfirming && (
          <span className="flex items-center gap-2">
            <Spinner size="sm" className="text-white" />
            Confirming...
          </span>
        )}
        {!isPending && !isConfirming && label}
      </Button>

      {hash && (
        <a
          href={getExplorerUrl(chainId, hash)}
          target="_blank"
          rel="noopener noreferrer"
          className="mt-2 block text-center text-xs text-indigo-600 hover:underline"
        >
          View on Explorer
        </a>
      )}

      {isSuccess && !isConfirming && (
        <p className="mt-2 text-center text-sm text-green-600">Transaction confirmed!</p>
      )}

      {error && (
        <p className="mt-2 text-center text-sm text-red-600">
          {error.message.length > 100 ? `${error.message.slice(0, 100)}...` : error.message}
        </p>
      )}
    </div>
  );
}
