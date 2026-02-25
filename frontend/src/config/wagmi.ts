"use client";

import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { polygon, polygonAmoy } from "wagmi/chains";

export const config = getDefaultConfig({
  appName: "AI Model Marketplace",
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || "demo",
  chains: [polygonAmoy, polygon],
  ssr: true,
});
