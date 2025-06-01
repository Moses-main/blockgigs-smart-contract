# FreelanceEscrow Smart Contract

## A Solidity smart contract for managing freelance jobs using an escrow system. It allows clients to post jobs with deposits, and freelancers to accept them. Funds are held in escrow until the job is completed, and then released to the freelancer.

## 🛠 Features

- Clients create jobs with a deposit
- Freelancers accept jobs
- Clients mark jobs as completed
- Funds released securely to freelancers
- Jobs can be cancelled before acceptance (with refund)
- Events emitted for all state changes
- Reentrancy protection

---

## 📦 Prerequisites

- [Remix IDE](https://remix.ethereum.org) (online)
- MetaMask or any Web3-compatible wallet connected to a testnet (e.g., Sepolia or Goerli)
- Testnet ETH (can be requested from public faucets)

---

## 📁 File Structure

```plaintext
FreelanceEscrow.sol   # Main smart contract
README.md             # This documentation
```

---

## 🚀 Deploying with Remix

1. **Open Remix**
   Go to [Remix IDE](https://remix.ethereum.org)

2. **Create the Contract File**

   - In the `contracts/` folder, create a new file: `FreelanceEscrow.sol`
   - Paste the contract code into the file

3. **Compile**

   - Go to the "Solidity Compiler" tab
   - Select compiler version `0.8.x`
   - Click **Compile FreelanceEscrow\.sol**

4. **Deploy**

   - Go to the "Deploy & Run Transactions" tab
   - Select **Injected Provider - Metamask** under Environment
   - Ensure your wallet is connected to a testnet (e.g., Sepolia)
   - Select the `FreelanceEscrow` contract
   - Click **Deploy**
   - Confirm transaction in MetaMask

---

## 🧪 Testing the Contract

> You can interact with the contract directly in Remix after deployment:

### 1. Create a Job

- Set `value` (in ETH) > 0 in the Deploy tab
- Input parameters:

  - `_freelancer`: a valid address (not your own)
  - `_ipfsHash`: a sample IPFS hash (e.g., `"Qm...abc"`)

- Call `createJob(address, string)`
  ✅ Emits `JobCreated`

### 2. Accept the Job

- Switch wallet to the freelancer account
- Call `acceptJob(jobId)`
  ✅ Emits `JobAccepted`

### 3. Complete the Job

- Switch back to the client wallet
- Call `completeJob(jobId)`
  ✅ Emits `JobCompleted`

### 4. Release Funds

- Call `releaseFunds(jobId)`
  ✅ Emits `FundsReleased` and transfers ETH to freelancer

### 5. Cancel the Job

- Only possible before job is accepted
- Call `cancelJob(jobId)`
  ✅ Emits `JobCancelled` and refunds client

### 6. View Functions

Use the following view functions to inspect the contract state:

- `getJob(jobId)`
- `getTotalJobs()`
- `getClientJobs(address)`
- `getFreelancerJobs(address)`

---

## 🧾 Verifying the Contract on Etherscan

To verify the contract on Etherscan:

1. **Copy the Flattened Code**

   - In Remix, go to the **File Explorer**
   - Right-click on `FreelanceEscrow.sol`, click **Flatten**

2. **Verify on Etherscan**

   - Go to [Etherscan Verify](https://sepolia.etherscan.io/verifyContract) (based on the testnet you deployed to)
   - Fill in:

     - Compiler version: 0.8.x
     - License: MIT

   - Paste flattened source code
   - Submit

---

## ⚠️ Notes

- Make sure to **switch accounts** in MetaMask when simulating different roles (Client vs Freelancer)
- Always test with testnet ETH, not mainnet

---

## 📜 License

MIT License. See `SPDX-License-Identifier: MIT` in the source code.

---
