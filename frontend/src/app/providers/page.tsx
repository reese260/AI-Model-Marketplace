"use client";

import { Card, CardTitle } from "@/components/ui/Card";
import { Alert } from "@/components/ui/Alert";

export default function ProvidersPage() {
  return (
    <div className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
      <h1 className="mb-8 text-3xl font-bold text-gray-900">Provider Directory</h1>

      <Alert variant="info" className="mb-6">
        Provider directory requires a subgraph or indexer to enumerate registered providers.
        Currently, you can look up individual providers by address.
      </Alert>

      <Card>
        <CardTitle>Look Up Provider</CardTitle>
        <form
          className="mt-4 flex gap-3"
          onSubmit={(e) => {
            e.preventDefault();
            const form = e.target as HTMLFormElement;
            const input = form.elements.namedItem("address") as HTMLInputElement;
            if (input.value) {
              window.location.href = `/providers/${input.value}`;
            }
          }}
        >
          <input
            name="address"
            placeholder="0x... provider address"
            className="flex-1 rounded-lg border border-gray-300 px-3 py-2 text-sm"
          />
          <button
            type="submit"
            className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
          >
            View Profile
          </button>
        </form>
      </Card>
    </div>
  );
}
