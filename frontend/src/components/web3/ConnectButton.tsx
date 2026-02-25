"use client";

import { ConnectButton as RainbowConnectButton } from "@rainbow-me/rainbowkit";

export function ConnectButton() {
  return (
    <RainbowConnectButton
      chainStatus="icon"
      showBalance={{ smallScreen: false, largeScreen: true }}
      accountStatus={{ smallScreen: "avatar", largeScreen: "full" }}
    />
  );
}
