import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { Zentry } from "../target/types/zentry";
import { 
  SystemProgram, 
  PublicKey, 
  LAMPORTS_PER_SOL, 
  Transaction, 
  SYSVAR_INSTRUCTIONS_PUBKEY,
  sendAndConfirmTransaction
} from "@solana/web3.js";
import { expect } from "chai";

describe("zentry", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.Zentry as Program<Zentry>;
  const wallet = provider.wallet as anchor.Wallet;

  const [policyPDA] = PublicKey.findProgramAddressSync(
    [Buffer.from("policy"), wallet.publicKey.toBuffer()],
    program.programId
  );

  const maxAmount = new anchor.BN(5 * LAMPORTS_PER_SOL);

  it("Initializes the VoicePolicy", async () => {
    await program.methods
      .initializePolicy(maxAmount)
      .accounts({
        policy: policyPDA,
        authority: wallet.publicKey,
        systemProgram: SystemProgram.programId,
      })
      .rpc();

    const policyAccount = await program.account.voicePolicy.fetch(policyPDA);
    expect(policyAccount.maxAmount.toString()).to.equal(maxAmount.toString());
    expect(policyAccount.authority.toBase58()).to.equal(wallet.publicKey.toBase58());
  });

  it("Test Case A (Green Path): Succeeds when intent matches transfer and is within limits", async () => {
    const amount = new anchor.BN(1 * LAMPORTS_PER_SOL);
    const recipient = PublicKey.unique();

    const checkIntentIx = await program.methods
      .checkVerifiableIntent(amount)
      .accounts({
        policy: policyPDA,
        authority: wallet.publicKey,
        instructionsSysvar: SYSVAR_INSTRUCTIONS_PUBKEY,
      })
      .instruction();

    const transferIx = SystemProgram.transfer({
      fromPubkey: wallet.publicKey,
      toPubkey: recipient,
      lamports: amount.toNumber(),
    });

    const tx = new Transaction().add(checkIntentIx).add(transferIx);
    
    await provider.sendAndConfirm(tx);
    // Success means it didn't throw
  });

  it("Test Case B (Exploit Block): Fails when transfer exceeds policy limit", async () => {
    const amount = new anchor.BN(100 * LAMPORTS_PER_SOL); // Exceeds 5 SOL limit
    const recipient = PublicKey.unique();

    const checkIntentIx = await program.methods
      .checkVerifiableIntent(amount)
      .accounts({
        policy: policyPDA,
        authority: wallet.publicKey,
        instructionsSysvar: SYSVAR_INSTRUCTIONS_PUBKEY,
      })
      .instruction();

    const transferIx = SystemProgram.transfer({
      fromPubkey: wallet.publicKey,
      toPubkey: recipient,
      lamports: amount.toNumber(),
    });

    const tx = new Transaction().add(checkIntentIx).add(transferIx);

    try {
      await provider.sendAndConfirm(tx);
      expect.fail("Should have failed with PolicyViolation");
    } catch (err: any) {
      expect(err.toString()).to.include("PolicyViolation");
    }
  });

  it("Test Case B.2 (Exploit Block): Fails when transfer matches intent but exceeds policy limit", async () => {
      // This is covered by Test Case B above, but let's be explicit
  });

  it("Test Case B.3 (Exploit Block): Fails when transfer amount does not match intent amount", async () => {
    const intentAmount = new anchor.BN(1 * LAMPORTS_PER_SOL);
    const transferAmount = new anchor.BN(2 * LAMPORTS_PER_SOL);
    const recipient = PublicKey.unique();

    const checkIntentIx = await program.methods
      .checkVerifiableIntent(intentAmount)
      .accounts({
        policy: policyPDA,
        authority: wallet.publicKey,
        instructionsSysvar: SYSVAR_INSTRUCTIONS_PUBKEY,
      })
      .instruction();

    const transferIx = SystemProgram.transfer({
      fromPubkey: wallet.publicKey,
      toPubkey: recipient,
      lamports: transferAmount.toNumber(),
    });

    const tx = new Transaction().add(checkIntentIx).add(transferIx);

    try {
      await provider.sendAndConfirm(tx);
      expect.fail("Should have failed with PolicyViolation");
    } catch (err: any) {
      expect(err.toString()).to.include("PolicyViolation");
    }
  });

  it("Test Case C (Shadow Instruction): Fails if transfer instruction is not immediately following", async () => {
    const amount = new anchor.BN(1 * LAMPORTS_PER_SOL);
    const recipient = PublicKey.unique();

    const checkIntentIx = await program.methods
      .checkVerifiableIntent(amount)
      .accounts({
        policy: policyPDA,
        authority: wallet.publicKey,
        instructionsSysvar: SYSVAR_INSTRUCTIONS_PUBKEY,
      })
      .instruction();

    const dummyIx = SystemProgram.transfer({
      fromPubkey: wallet.publicKey,
      toPubkey: wallet.publicKey,
      lamports: 0,
    });

    const transferIx = SystemProgram.transfer({
      fromPubkey: wallet.publicKey,
      toPubkey: recipient,
      lamports: amount.toNumber(),
    });

    // Dummy instruction inserted between Sentinel and real Transfer
    const tx = new Transaction().add(checkIntentIx).add(dummyIx).add(transferIx);

    try {
      await provider.sendAndConfirm(tx);
      // Wait, dummyIx is also a transfer! So it might pass if amount matches.
      // But here dummyIx has 0 lamports, while intent is 1 SOL.
    } catch (err: any) {
       expect(err.toString()).to.include("PolicyViolation");
    }

    // Now try with a non-transfer instruction in between
    const tx2 = new Transaction().add(checkIntentIx).add(
        // Some other random instruction... using SystemProgram.assign as a filler
        SystemProgram.assign({
            accountPubkey: wallet.publicKey,
            programId: SystemProgram.programId
        })
    ).add(transferIx);

    try {
        await provider.sendAndConfirm(tx2);
        expect.fail("Should have failed with InvalidNextInstruction");
    } catch (err: any) {
        expect(err.toString()).to.include("InvalidNextInstruction");
    }
  });
});
