"use client";

import { useEffect, useState } from "react";
import { usePublicClient, useWatchContractEvent } from "wagmi";
import { parseAbiItem } from "viem";
import { JobMarketplaceAbi } from "@/contracts/abis/JobMarketplace";
import { useContractAddress } from "@/config/contracts";

interface JobCreatedEvent {
  jobId: `0x${string}`;
  requester: `0x${string}`;
  paymentAmount: bigint;
  jobDetailsIPFS: string;
  blockNumber: bigint;
}

export function useJobCreatedEvents() {
  const address = useContractAddress("JobMarketplace");
  const publicClient = usePublicClient();
  const [events, setEvents] = useState<JobCreatedEvent[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Fetch historical events
  useEffect(() => {
    if (!publicClient || !address || address === "0x0000000000000000000000000000000000000000") {
      setIsLoading(false);
      return;
    }

    const fetchEvents = async () => {
      try {
        const logs = await publicClient.getLogs({
          address,
          event: parseAbiItem(
            "event JobCreated(bytes32 indexed jobId, address indexed requester, uint256 paymentAmount, string jobDetailsIPFS)"
          ),
          fromBlock: "earliest",
          toBlock: "latest",
        });

        const parsed = logs.map((log) => ({
          jobId: log.args.jobId!,
          requester: log.args.requester!,
          paymentAmount: log.args.paymentAmount!,
          jobDetailsIPFS: log.args.jobDetailsIPFS!,
          blockNumber: log.blockNumber,
        }));

        setEvents(parsed);
      } catch (err) {
        console.error("Failed to fetch JobCreated events:", err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchEvents();
  }, [publicClient, address]);

  // Watch for new events in real-time
  useWatchContractEvent({
    address,
    abi: JobMarketplaceAbi,
    eventName: "JobCreated",
    onLogs(logs) {
      const newEvents = logs.map((log) => {
        const args = log.args as {
          jobId: `0x${string}`;
          requester: `0x${string}`;
          paymentAmount: bigint;
          jobDetailsIPFS: string;
        };
        return {
          jobId: args.jobId,
          requester: args.requester,
          paymentAmount: args.paymentAmount,
          jobDetailsIPFS: args.jobDetailsIPFS,
          blockNumber: log.blockNumber,
        };
      });
      setEvents((prev) => [...prev, ...newEvents]);
    },
  });

  return { events, isLoading };
}
