import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { VoicePolicy } from "../target/types/voice_policy";
import { assert } from "chai";

describe("voice_policy", () => {
  // Configure the client to use the local cluster.
  anchor.setProvider(anchor.AnchorProvider.env());

  const program = anchor.workspace.VoicePolicy as Program<VoicePolicy>;

  it("Is initialized!", async () => {
    // 1. Initialize the policy
    // const txInit = await program.methods.initializePolicy(new anchor.BN(1000000000), []).rpc();
    
    // 2. Test the Security Middleware (Introspection)
    // To test this, you must construct a transaction containing MULTIPLE instructions:
    //   a. checkVerifiableIntent
    //   b. SystemProgram.transfer (or TokenProgram.transfer)
    // The checkVerifiableIntent instruction will introspect the transaction, find the transfer,
    // and verify it against the VoicePolicy PDA.
    
    /*
    const tx = new anchor.web3.Transaction()
      .add(
        await program.methods.checkVerifiableIntent().accounts({
          voicePolicy: pdaAddress,
          authority: wallet.publicKey,
          instructions: anchor.web3.SYSVAR_INSTRUCTIONS_PUBKEY,
        }).instruction()
      )
      .add(
        anchor.web3.SystemProgram.transfer({
          fromPubkey: wallet.publicKey,
          toPubkey: someRecipient,
          lamports: 1000,
        })
      );
    await anchor.web3.sendAndConfirmTransaction(provider.connection, tx, [wallet.payer]);
    */
  });
});
