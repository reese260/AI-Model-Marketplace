export const JobMarketplaceAbi = [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "_reputationNFT",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "_providerStaking",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "_trainingVerification",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "_escrow",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "applyForJob",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "providerType",
        "type": "uint8",
        "internalType": "enum ProviderStaking.ProviderType"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "assignProviders",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "dataProvider",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "computeProvider",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "cancelJob",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "computeProviderApplicants",
    "inputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "createJob",
    "inputs": [
      {
        "name": "jobDetailsIPFS",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "dataProviderShare",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "computeProviderShare",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "requiredStakeData",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "requiredStakeCompute",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "deadline",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "createJobWithZKRequirements",
    "inputs": [
      {
        "name": "jobDetailsIPFS",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "dataProviderShare",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "computeProviderShare",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "requiredStakeData",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "requiredStakeCompute",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "deadline",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "requiresZKProof",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "zkProofBonus",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "payable"
  },
  {
    "type": "function",
    "name": "dataProviderApplicants",
    "inputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "disputeJob",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "escrow",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract ModelTrainingEscrow"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "finalizeJob",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getJob",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "tuple",
        "internalType": "struct JobMarketplace.Job",
        "components": [
          {
            "name": "jobId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "requester",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "dataProvider",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "computeProvider",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "jobDetailsIPFS",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "datasetHashIPFS",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "paymentAmount",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "requiredStakeData",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "requiredStakeCompute",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "dataProviderShare",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "computeProviderShare",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "createdAt",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "deadline",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "status",
            "type": "uint8",
            "internalType": "enum JobMarketplace.JobStatus"
          },
          {
            "name": "datasetCommitment",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "requiresZKProof",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "zkProofBonus",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "usedZKProof",
            "type": "bool",
            "internalType": "bool"
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getJobApplicants",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "dataApplicants",
        "type": "address[]",
        "internalType": "address[]"
      },
      {
        "name": "computeApplicants",
        "type": "address[]",
        "internalType": "address[]"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "jobs",
    "inputs": [
      {
        "name": "",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "requester",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "dataProvider",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "computeProvider",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "jobDetailsIPFS",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "datasetHashIPFS",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "paymentAmount",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "requiredStakeData",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "requiredStakeCompute",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "dataProviderShare",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "computeProviderShare",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "createdAt",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "deadline",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "status",
        "type": "uint8",
        "internalType": "enum JobMarketplace.JobStatus"
      },
      {
        "name": "datasetCommitment",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "requiresZKProof",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "zkProofBonus",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "usedZKProof",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "owner",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "providerStaking",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract ProviderStaking"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "renounceOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "reputationNFT",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract ReputationNFT"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "submitTraining",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "modelHashIPFS",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "metricsHashIPFS",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "submitTrainingWithProof",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "modelHashIPFS",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "metricsHashIPFS",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "modelCommitment",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "metricsCommitment",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "proof",
        "type": "uint256[8]",
        "internalType": "uint256[8]"
      },
      {
        "name": "publicInputs",
        "type": "uint256[]",
        "internalType": "uint256[]"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "trainingVerification",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract TrainingVerification"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "transferOwnership",
    "inputs": [
      {
        "name": "newOwner",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "uploadDataset",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "datasetHashIPFS",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "uploadDatasetWithCommitment",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "datasetHashIPFS",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "datasetCommitment",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "event",
    "name": "DatasetCommitmentSet",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "commitment",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "DatasetUploaded",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "datasetHashIPFS",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "JobCancelled",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "JobCompleted",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "JobCompletedWithZKBonus",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "zkBonus",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "JobCreated",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "requester",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "paymentAmount",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
      },
      {
        "name": "jobDetailsIPFS",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "JobDisputed",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "disputer",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "OwnershipTransferred",
    "inputs": [
      {
        "name": "previousOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newOwner",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ProviderApplied",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "provider",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "providerType",
        "type": "uint8",
        "indexed": false,
        "internalType": "enum ProviderStaking.ProviderType"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "ProvidersAssigned",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "dataProvider",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      },
      {
        "name": "computeProvider",
        "type": "address",
        "indexed": false,
        "internalType": "address"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "TrainingStarted",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "TrainingSubmittedForVerification",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "modelHashIPFS",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "TrainingSubmittedWithZKProof",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "modelHashIPFS",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "proofHash",
        "type": "bytes32",
        "indexed": false,
        "internalType": "bytes32"
      }
    ],
    "anonymous": false
  },
  {
    "type": "error",
    "name": "OwnableInvalidOwner",
    "inputs": [
      {
        "name": "owner",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "OwnableUnauthorizedAccount",
    "inputs": [
      {
        "name": "account",
        "type": "address",
        "internalType": "address"
      }
    ]
  },
  {
    "type": "error",
    "name": "ReentrancyGuardReentrantCall",
    "inputs": []
  }
] as const;
