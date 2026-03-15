import { formatEther as viemFormatEther, type Address } from "viem";
import {
  JobStatus,
  ProviderType,
  VerificationStatus,
  EscrowStatus,
} from "./types";

export function formatAddress(address: string): string {
  if (!address || address.length < 10) return address;
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

export function formatEth(wei: bigint): string {
  return viemFormatEther(wei);
}

export function formatEthShort(wei: bigint): string {
  const eth = Number(viemFormatEther(wei));
  if (eth === 0) return "0";
  if (eth < 0.001) return "<0.001";
  return eth.toFixed(3);
}

export function formatBps(bps: bigint | number): string {
  return `${Number(bps) / 100}%`;
}

export function formatTimestamp(timestamp: bigint): string {
  return new Date(Number(timestamp) * 1000).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function timeFromNow(timestamp: bigint): string {
  const now = Math.floor(Date.now() / 1000);
  const diff = Number(timestamp) - now;

  if (diff < 0) return "expired";
  if (diff < 60) return `${diff}s`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h`;
  return `${Math.floor(diff / 86400)}d`;
}

export function isDeadlinePassed(deadline: bigint): boolean {
  return Number(deadline) < Math.floor(Date.now() / 1000);
}

export const ZERO_ADDRESS: Address =
  "0x0000000000000000000000000000000000000000";

export function isZeroAddress(address: string): boolean {
  return address === ZERO_ADDRESS;
}

export const JOB_STATUS_LABELS: Record<JobStatus, string> = {
  [JobStatus.OPEN]: "Open",
  [JobStatus.IN_PROGRESS]: "In Progress",
  [JobStatus.SUBMITTED]: "Submitted",
  [JobStatus.COMPLETED]: "Completed",
  [JobStatus.CANCELLED]: "Cancelled",
  [JobStatus.DISPUTED]: "Disputed",
};

export const JOB_STATUS_COLORS: Record<JobStatus, string> = {
  [JobStatus.OPEN]: "bg-green-100 text-green-800",
  [JobStatus.IN_PROGRESS]: "bg-blue-100 text-blue-800",
  [JobStatus.SUBMITTED]: "bg-yellow-100 text-yellow-800",
  [JobStatus.COMPLETED]: "bg-purple-100 text-purple-800",
  [JobStatus.CANCELLED]: "bg-gray-100 text-gray-800",
  [JobStatus.DISPUTED]: "bg-red-100 text-red-800",
};

export const PROVIDER_TYPE_LABELS: Record<ProviderType, string> = {
  [ProviderType.DATA]: "Data Provider",
  [ProviderType.COMPUTE]: "Compute Provider",
};

export const VERIFICATION_STATUS_LABELS: Record<VerificationStatus, string> = {
  [VerificationStatus.PENDING]: "Pending",
  [VerificationStatus.ZK_VERIFIED]: "ZK Verified",
  [VerificationStatus.VERIFIED]: "Verified",
  [VerificationStatus.DISPUTED]: "Disputed",
  [VerificationStatus.REJECTED]: "Rejected",
};

export const VERIFICATION_STATUS_COLORS: Record<VerificationStatus, string> = {
  [VerificationStatus.PENDING]: "bg-yellow-100 text-yellow-800",
  [VerificationStatus.ZK_VERIFIED]: "bg-indigo-100 text-indigo-800",
  [VerificationStatus.VERIFIED]: "bg-green-100 text-green-800",
  [VerificationStatus.DISPUTED]: "bg-red-100 text-red-800",
  [VerificationStatus.REJECTED]: "bg-gray-100 text-gray-800",
};

export const ESCROW_STATUS_LABELS: Record<EscrowStatus, string> = {
  [EscrowStatus.ACTIVE]: "Active",
  [EscrowStatus.COMPLETED]: "Completed",
  [EscrowStatus.RELEASED]: "Released",
  [EscrowStatus.REFUNDED]: "Refunded",
  [EscrowStatus.DISPUTED]: "Disputed",
};

export function cn(...classes: (string | undefined | false)[]): string {
  return classes.filter(Boolean).join(" ");
}

export function getExplorerUrl(
  chainId: number,
  hash: string,
  type: "tx" | "address" = "tx"
): string {
  const base =
    chainId === 137
      ? "https://polygonscan.com"
      : "https://mumbai.polygonscan.com";
  return `${base}/${type}/${hash}`;
}
