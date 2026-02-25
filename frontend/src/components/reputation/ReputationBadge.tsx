import { cn } from "@/lib/utils";
import { MAX_REPUTATION_SCORE } from "@/config/constants";

interface ReputationBadgeProps {
  score: bigint;
  className?: string;
}

export function ReputationBadge({ score, className }: ReputationBadgeProps) {
  const numScore = Number(score);
  const pct = (numScore / MAX_REPUTATION_SCORE) * 100;

  let color = "bg-gray-100 text-gray-800";
  if (pct >= 80) color = "bg-green-100 text-green-800";
  else if (pct >= 60) color = "bg-blue-100 text-blue-800";
  else if (pct >= 40) color = "bg-yellow-100 text-yellow-800";
  else if (pct > 0) color = "bg-red-100 text-red-800";

  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
        color,
        className
      )}
    >
      {numScore} / {MAX_REPUTATION_SCORE}
    </span>
  );
}
