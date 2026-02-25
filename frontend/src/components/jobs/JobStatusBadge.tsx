import { cn } from "@/lib/utils";
import { JobStatus } from "@/lib/types";
import { JOB_STATUS_LABELS, JOB_STATUS_COLORS } from "@/lib/utils";

interface JobStatusBadgeProps {
  status: JobStatus;
  className?: string;
}

export function JobStatusBadge({ status, className }: JobStatusBadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
        JOB_STATUS_COLORS[status],
        className
      )}
    >
      {JOB_STATUS_LABELS[status]}
    </span>
  );
}
