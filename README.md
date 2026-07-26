# Automated Web3 Security Pipeline (Foundry & Slither CI)

An enterprise-grade, security-first smart contract development repository demonstrating an automated **Continuous Integration (CI) Security Pipeline** built via GitHub Actions.

This repository intentionally contains a **Vulnerable Vault** contract to showcase how static analysis gates and automated testing frameworks work together to intercept critical vulnerabilities (like Reentrancy) before code can reach a production environment.

---

## Automated CI Pipeline Architecture

The workflow file located at `.github/workflows/test.yml` acts as an automated quality-and-security fence on every commit and Pull Request. It executes the following 4 stages sequentially:

[ Push / PR ]
│
▼
┌──────────────┐
│ Forge Fmt │ ──► Enforces strict styling & readability standards
└──────────────┘
│
▼
┌──────────────┐
│ Forge Build │ ──► Compiles bytecode & enforces EIP-170 contract size checks (<24KB)
└──────────────┘
│
▼
┌──────────────┐
│ Forge Test │ ──► Runs functional unit tests & Proof-of-Concept (PoC) exploit scripts
└──────────────┘
│
▼
┌──────────────┐
│ Slither Scan │ ──► Deep static analysis; blocks the pipeline on Medium/High flaws
└──────────────┘

---

## The Vulnerability: Reentrancy (CEI Violation)

The `VulnerableVault.sol` contract contains a classical **Reentrancy** vulnerability inside its `withdraw()` function. It transfers Ether to an external address using a low-level `.call` loop _before_ modifying the user's internal ledger balance, violating the **Checks-Effects-Interactions (CEI)** architectural pattern:

```solidity
// VULNERABLE PATTERN DETECTED BY SLITHER
function withdraw() public {
    uint256 balance = balances[msg.sender];
    require(balance > 0, "No balance to withdraw");

    // INTERACTION BEFORE EFFECT: Control is handed to an untrusted contract
    (bool success, ) = msg.sender.call{value: balance}("");
    require(success, "Transfer failed");

    balances[msg.sender] = 0; // Triggered too late
}
```

---

## Proof of Concept (PoC) Exploit

To validate the impact of this architectural risk, `test/VulnerableVault.t.sol` implements a malicious `ReentrancyAttacker` contract.

When executed via `forge test`, the contract intercepts the execution string through its `receive()` callback loop, re-entering the vault multiple times until the underlying liquidity pool is entirely drained:

- **Initial Vault State:** 3 ETH (Innocent Funds)
- **Attacker Input:** 1 ETH
- **Post-Attack Attacker State:** 4 ETH (All physical protocol funds successfully exfiltrated)

---

## Intentional Pipeline Status: FAILED (❌)

**Note to Reviewers / Hiring Managers:** The red failing cross badge on this repository is **by design**.

1. **Foundry Tests Pass:** The `forge test` block executes successfully because our PoC exploit test accurately validates and asserts that the vault _can_ be drained to 0.
2. **Slither Blocks Deployment:** The pipeline halts at the final stage because **Slither flags the High-Severity Reentrancy anomaly (`reentrancy-eth`)** and throws exit code `255`, successfully preventing the broken codebase from clearing the security check.

This behavior demonstrates a functioning production security gateway: **Vulnerable code is blocked from ever passing integration validation checks.**
