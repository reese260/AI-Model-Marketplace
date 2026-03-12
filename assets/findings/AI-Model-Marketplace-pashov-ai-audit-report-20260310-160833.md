# 🔐 Security Review — AI-Model-Marketplace

---

## Scope

|                                  |                                                        |
| -------------------------------- | ------------------------------------------------------ |
| **Mode**                         | ALL                                                    |
| **Files reviewed**               | `ProviderStaking.sol` · `ZKTrainingVerifier.sol` · `TrainingVerification.sol`<br>`ReputationNFT.sol` · `ReputationMath.sol` · `JobMarketplace.sol`<br>`ModelTrainingEscrow.sol` · `SlashingMath.sol` · `Groth16Verifier.sol` |
| **Confidence threshold (1-100)** | 80                                                     |

---

## Findings

[100] **1. Non-Atomic Proxy Initialization Allows Front-Running to Hijack Ownership**

`JobMarketplace.initialize` · `ModelTrainingEscrow.initialize` · `ProviderStaking.initialize` · `ReputationNFT.initialize` · `TrainingVerification.initialize` · `ZKTrainingVerifier.initialize` · Confidence: 100

**Description**
Every UUPS proxy contract exposes a public `initialize()` called in a separate transaction from deployment, so any attacker monitoring the mempool can front-run that call, become `owner`, then invoke `upgradeTo(maliciousImpl)` to drain all funds held by the contract system.

**Fix**

```diff
- proxy = new ERC1967Proxy(address(impl), "");
- // separate tx: impl.initialize(...)
+ proxy = new ERC1967Proxy(
+     address(impl),
+     abi.encodeCall(Contract.initialize, (arg1, arg2, ...))
+ );
```

Pass initialization calldata atomically in the proxy constructor (or use `upgradeToAndCall`) so no window exists between deployment and initialization.

---

[100] **2. ZK Bonus ETH Permanently Locked in Escrow on Refund**

`ModelTrainingEscrow._createEscrow` / `ModelTrainingEscrow.refundEscrow` · Confidence: 100

**Description**
`_createEscrow` stores only `baseAmount = msg.value - zkBonus` as `escrowData.totalAmount`, but `refundEscrow` returns only `escrowData.totalAmount` to the requester — leaving the entire `zkProofBonus` ETH permanently trapped in the contract with no recovery path.

**Fix**

```diff
  function refundEscrow(bytes32 jobId) external nonReentrant {
      // ...
      escrowData.status = EscrowStatus.REFUNDED;
-     (bool success, ) = escrowData.requester.call{value: escrowData.totalAmount}("");
-     require(success, "Refund failed");
-     emit EscrowRefunded(jobId, escrowData.totalAmount);
+     uint256 refundAmount = escrowData.totalAmount + escrowData.zkProofBonus;
+     (bool success, ) = escrowData.requester.call{value: refundAmount}("");
+     require(success, "Refund failed");
+     emit EscrowRefunded(jobId, refundAmount);
  }
```

---

[90] **3. Push Payment to Reverting Recipient Permanently Locks Escrow Funds**

`ModelTrainingEscrow.releaseEscrow` · Confidence: 90

**Description**
`releaseEscrow` sends ETH to `dataProvider`, `computeProvider`, and `feeRecipient` via three sequential `call{value}("")` each followed by a hard `require(success, ...)` — if any recipient is a contract that reverts on ETH receipt (or consumes excessive gas), the entire release reverts and all escrow funds are permanently locked with no pull-payment fallback.

**Fix**

```diff
- (bool dataSuccess, ) = escrowData.dataProvider.call{value: dataAmount}("");
- require(dataSuccess, "Data provider transfer failed");
- uint256 computeTotal = computeAmount + zkBonus;
- (bool computeSuccess, ) = escrowData.computeProvider.call{value: computeTotal}("");
- require(computeSuccess, "Compute provider transfer failed");
- (bool feeSuccess, ) = feeRecipient.call{value: feeAmount}("");
- require(feeSuccess, "Fee transfer failed");
+ // Use a pull-payment pattern
+ pendingWithdrawals[escrowData.dataProvider] += dataAmount;
+ pendingWithdrawals[escrowData.computeProvider] += computeAmount + zkBonus;
+ pendingWithdrawals[feeRecipient] += feeAmount;
+ // Add: function withdraw() external nonReentrant { ... }
```

---

[85] **4. Unrestricted `registerProvider` Allows Anyone to Permanently Grief Provider Registration**

`ReputationNFT.registerProvider` · Confidence: 85

**Description**
`registerProvider(address provider)` is `external` with no access control, so any caller can register an arbitrary address and consume its `providerToTokenId` slot — permanently preventing the victim address from self-registering since the function reverts with "Provider already registered."

**Fix**

```diff
  function registerProvider(address provider) external returns (uint256) {
+     require(authorizedUpdaters[msg.sender], "Not authorized to register");
      require(providerToTokenId[provider] == 0, "Provider already registered");
```

---

[85] **5. Integer Division Dust Permanently Locked in Escrow on Release**

`ModelTrainingEscrow.releaseEscrow` · Confidence: 85

**Description**
Three independent integer divisions — `(totalAmount * dataShare) / 10000`, `(totalAmount * computeShare) / 10000`, `(totalAmount * platformFee) / 10000` — each truncate independently, so their sum is less than `totalAmount`; the residual dust has no recipient and is permanently stranded in the contract with no sweep function.

**Fix**

```diff
  uint256 dataAmount = (totalAmount * escrowData.dataProviderShare) / 10000;
  uint256 computeAmount = (totalAmount * escrowData.computeProviderShare) / 10000;
- uint256 feeAmount = (totalAmount * escrowData.platformFee) / 10000;
+ uint256 feeAmount = totalAmount - dataAmount - computeAmount;
```

---

## Findings List

| # | Confidence | Title |
|---|---|---|
| 1 | [100] | Non-Atomic Proxy Initialization Allows Front-Running to Hijack Ownership |
| 2 | [100] | ZK Bonus ETH Permanently Locked in Escrow on Refund |
| 3 | [90] | Push Payment to Reverting Recipient Permanently Locks Escrow Funds |
| 4 | [85] | Unrestricted `registerProvider` Allows Anyone to Permanently Grief Provider Registration |
| 5 | [85] | Integer Division Dust Permanently Locked in Escrow on Release |
| | | **Below Confidence Threshold** |
| 6 | [75] | Deployer EOA Permanently Retains Owner Role Across All Contracts |

---

[75] **6. Deployer EOA Permanently Retains Owner Role Across All Contracts**

`All UUPS contracts — initialize()` · Confidence: 75

**Description**
Every contract calls `__Ownable_init(msg.sender)` in `initialize()` with no subsequent `transferOwnership()` to a multisig or timelock, leaving the deployer EOA as the sole permanent owner with unchecked power to upgrade implementations, set all authorization mappings, and reconfigure the platform.

---

> ⚠️ This review was performed by an AI assistant. AI analysis can never verify the complete absence of vulnerabilities and no guarantee of security is given. Team security reviews, bug bounty programs, and on-chain monitoring are strongly recommended. For a consultation regarding your projects' security, visit [https://www.pashov.com](https://www.pashov.com)
