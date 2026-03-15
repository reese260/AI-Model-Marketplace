export enum JobStatus {
  OPEN = 0,
  IN_PROGRESS = 1,
  SUBMITTED = 2,
  COMPLETED = 3,
  CANCELLED = 4,
  DISPUTED = 5,
}

export enum ProviderType {
  DATA = 0,
  COMPUTE = 1,
}

export enum VerificationStatus {
  PENDING = 0,
  ZK_VERIFIED = 1,
  VERIFIED = 2,
  DISPUTED = 3,
  REJECTED = 4,
}

export enum EscrowStatus {
  ACTIVE = 0,
  COMPLETED = 1,
  RELEASED = 2,
  REFUNDED = 3,
  DISPUTED = 4,
}

export interface Job {
  jobId: `0x${string}`;
  requester: `0x${string}`;
  dataProvider: `0x${string}`;
  computeProvider: `0x${string}`;
  jobDetailsIPFS: string;
  datasetHashIPFS: string;
  paymentAmount: bigint;
  requiredStakeData: bigint;
  requiredStakeCompute: bigint;
  dataProviderShare: bigint;
  computeProviderShare: bigint;
  createdAt: bigint;
  deadline: bigint;
  status: JobStatus;
  datasetCommitment: `0x${string}`;
  requiresZKProof: boolean;
  zkProofBonus: bigint;
  usedZKProof: boolean;
}

export interface StakeInfo {
  amount: bigint;
  lockedAmount: bigint;
  availableAmount: bigint;
  providerType: ProviderType;
  isActive: boolean;
  violationCount: bigint;
}

export interface ReputationData {
  score: bigint;
  totalJobsCompleted: bigint;
  totalJobsFailed: bigint;
  totalStakeSlashed: bigint;
  registrationTime: bigint;
  lastUpdateTime: bigint;
  zkProofsSubmitted: bigint;
}

export interface TrainingSubmission {
  jobId: `0x${string}`;
  computeProvider: `0x${string}`;
  modelHashIPFS: string;
  metricsHashIPFS: string;
  submissionTime: bigint;
  challengeDeadline: bigint;
  status: VerificationStatus;
  challenger: `0x${string}`;
  disputeReason: string;
  hasZKProof: boolean;
  datasetCommitment: `0x${string}`;
  modelCommitment: `0x${string}`;
  metricsCommitment: `0x${string}`;
  proofHash: `0x${string}`;
}

export interface EscrowDetails {
  jobId: `0x${string}`;
  requester: `0x${string}`;
  dataProvider: `0x${string}`;
  computeProvider: `0x${string}`;
  totalAmount: bigint;
  dataProviderShare: bigint;
  computeProviderShare: bigint;
  platformFee: bigint;
  createdAt: bigint;
  status: EscrowStatus;
  zkProofBonus: bigint;
}
