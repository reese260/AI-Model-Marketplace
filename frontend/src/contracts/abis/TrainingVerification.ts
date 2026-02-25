export const TrainingVerificationAbi = [
  {
    "type": "constructor",
    "inputs": [
      {
        "name": "_challengePeriod",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "authorizedSubmitters",
    "inputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [
      {
        "name": "",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "challengePeriod",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "challengeTraining",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "reason",
        "type": "string",
        "internalType": "string"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "getSubmission",
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
        "internalType": "struct TrainingVerification.TrainingSubmission",
        "components": [
          {
            "name": "jobId",
            "type": "bytes32",
            "internalType": "bytes32"
          },
          {
            "name": "computeProvider",
            "type": "address",
            "internalType": "address"
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
            "name": "submissionTime",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "challengeDeadline",
            "type": "uint256",
            "internalType": "uint256"
          },
          {
            "name": "status",
            "type": "uint8",
            "internalType": "enum TrainingVerification.VerificationStatus"
          },
          {
            "name": "challenger",
            "type": "address",
            "internalType": "address"
          },
          {
            "name": "disputeReason",
            "type": "string",
            "internalType": "string"
          },
          {
            "name": "hasZKProof",
            "type": "bool",
            "internalType": "bool"
          },
          {
            "name": "datasetCommitment",
            "type": "bytes32",
            "internalType": "bytes32"
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
            "name": "proofHash",
            "type": "bytes32",
            "internalType": "bytes32"
          }
        ]
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "getVerificationStatus",
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
        "type": "uint8",
        "internalType": "enum TrainingVerification.VerificationStatus"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "isInChallengePeriod",
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
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "isTrainingVerified",
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
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "isZKVerified",
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
    "name": "renounceOwnership",
    "inputs": [],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "resolveDispute",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "accepted",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setAuthorizedSubmitter",
    "inputs": [
      {
        "name": "submitter",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "authorized",
        "type": "bool",
        "internalType": "bool"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "setZKVerifier",
    "inputs": [
      {
        "name": "_zkVerifier",
        "type": "address",
        "internalType": "address"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "submissions",
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
        "name": "computeProvider",
        "type": "address",
        "internalType": "address"
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
        "name": "submissionTime",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "challengeDeadline",
        "type": "uint256",
        "internalType": "uint256"
      },
      {
        "name": "status",
        "type": "uint8",
        "internalType": "enum TrainingVerification.VerificationStatus"
      },
      {
        "name": "challenger",
        "type": "address",
        "internalType": "address"
      },
      {
        "name": "disputeReason",
        "type": "string",
        "internalType": "string"
      },
      {
        "name": "hasZKProof",
        "type": "bool",
        "internalType": "bool"
      },
      {
        "name": "datasetCommitment",
        "type": "bytes32",
        "internalType": "bytes32"
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
        "name": "proofHash",
        "type": "bytes32",
        "internalType": "bytes32"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "function",
    "name": "submitTrainingResult",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "computeProvider",
        "type": "address",
        "internalType": "address"
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
    "name": "submitTrainingWithZKProof",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "internalType": "bytes32"
      },
      {
        "name": "computeProvider",
        "type": "address",
        "internalType": "address"
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
        "name": "datasetCommitment",
        "type": "bytes32",
        "internalType": "bytes32"
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
    "name": "updateChallengePeriod",
    "inputs": [
      {
        "name": "newPeriod",
        "type": "uint256",
        "internalType": "uint256"
      }
    ],
    "outputs": [],
    "stateMutability": "nonpayable"
  },
  {
    "type": "function",
    "name": "verifyTraining",
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
    "name": "zkVerifier",
    "inputs": [],
    "outputs": [
      {
        "name": "",
        "type": "address",
        "internalType": "contract IZKVerifier"
      }
    ],
    "stateMutability": "view"
  },
  {
    "type": "event",
    "name": "DisputeResolved",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "accepted",
        "type": "bool",
        "indexed": false,
        "internalType": "bool"
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
    "name": "TrainingChallenged",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "challenger",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "reason",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      }
    ],
    "anonymous": false
  },
  {
    "type": "event",
    "name": "TrainingRejected",
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
    "name": "TrainingSubmitted",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
      },
      {
        "name": "computeProvider",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "modelHashIPFS",
        "type": "string",
        "indexed": false,
        "internalType": "string"
      },
      {
        "name": "challengeDeadline",
        "type": "uint256",
        "indexed": false,
        "internalType": "uint256"
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
        "name": "computeProvider",
        "type": "address",
        "indexed": true,
        "internalType": "address"
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
    "type": "event",
    "name": "TrainingVerified",
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
    "name": "TrainingZKVerified",
    "inputs": [
      {
        "name": "jobId",
        "type": "bytes32",
        "indexed": true,
        "internalType": "bytes32"
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
    "type": "event",
    "name": "ZKVerifierUpdated",
    "inputs": [
      {
        "name": "oldVerifier",
        "type": "address",
        "indexed": true,
        "internalType": "address"
      },
      {
        "name": "newVerifier",
        "type": "address",
        "indexed": true,
        "internalType": "address"
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
  }
] as const;
