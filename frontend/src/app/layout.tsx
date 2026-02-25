import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Providers } from "./providers";
import { Header } from "@/components/layout/Header";
import { Footer } from "@/components/layout/Footer";
import { NetworkGuard } from "@/components/web3/NetworkGuard";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "AI Model Marketplace",
  description:
    "Decentralized marketplace for AI model training on Polygon",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${inter.className} antialiased`}>
        <Providers>
          <div className="flex min-h-screen flex-col">
            <Header />
            <NetworkGuard>
              <main className="flex-1">{children}</main>
            </NetworkGuard>
            <Footer />
          </div>
        </Providers>
      </body>
    </html>
  );
}
