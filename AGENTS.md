# Zentry Protocol: Agent Coordination Contract

## 1. Directory Ownership
- **Agent: Jules (Cloud)** -> Path: `/programs/zentry/` & `/tests/`
  - Focus: Anchor/Rust security logic, Instruction Introspection, and Security Unit Tests.
- **Agent: Antigravity (Local)** -> Path: `/app/`
  - Focus: Flutter UI, Stitch State, MWA Connection, and ElevenLabs WebSocket.

## 2. On-Chain Interface (The Sentinel)
The Rust program implements the following instruction that the Flutter app must call:
- **Instruction:** `check_verifiable_intent`
- **Arguments:** `amount: u64`
- **Accounts:**
  1. `policy`: [Account] The User's VoicePolicy PDA.
  2. `authority`: [Signer] The User's wallet.
  3. `instructions_sysvar`: [Sysvar] Required for introspection.

## 3. The Security Protocol
For every voice-generated transaction, the Flutter app MUST bundle instructions in this order:
1. `zentry::check_verifiable_intent(amount)`
2. `system_program::transfer(amount)`

**Note:** If the amount in Instruction 2 does not match Instruction 1 or violates the PDA limit, the Rust program MUST return `ErrorCode::PolicyViolation`.

## 4. State Management (Stitch)
- **IntentStore:** Tracks `voice_input`, `predicted_amount`, `verification_status`, and `transaction_signature`.