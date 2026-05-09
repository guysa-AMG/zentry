use anchor_lang::prelude::*;
use anchor_lang::solana_program::sysvar::instructions::{
    load_current_index_checked, load_instruction_at_checked,
};
use anchor_lang::solana_program::system_program;

declare_id!("Zen1111111111111111111111111111111111111111");

#[program]
pub mod zentry {
    use super::*;

    pub fn initialize_policy(ctx: Context<InitializePolicy>, max_amount: u64) -> Result<()> {
        let policy = &mut ctx.accounts.policy;
        policy.max_amount = max_amount;
        policy.authority = ctx.accounts.authority.key();
        Ok(())
    }

    pub fn check_verifiable_intent(ctx: Context<CheckVerifiableIntent>, amount: u64) -> Result<()> {
        let policy = &ctx.accounts.policy;
        let instructions_sysvar = &ctx.accounts.instructions_sysvar;

        // 1. Policy Enforcement: check if requested amount is within policy limits
        if amount > policy.max_amount {
            return err!(ErrorCode::PolicyViolation);
        }

        // 2. Instruction Introspection
        let current_index = load_current_index_checked(instructions_sysvar)?;
        let next_ix = load_instruction_at_checked((current_index + 1) as usize, instructions_sysvar)
            .map_err(|_| ErrorCode::MissingTransferInstruction)?;

        // 3. Verify next instruction is System Program Transfer
        if next_ix.program_id != system_program::ID {
            return err!(ErrorCode::InvalidNextInstruction);
        }

        // 4. Deserialize Transfer data to extract lamports
        // System Program Transfer instruction data layout:
        // u32 (instruction index = 2 for transfer)
        // u64 (lamports)
        if next_ix.data.len() < 12 {
            return err!(ErrorCode::InvalidTransferData);
        }

        let ix_type = u32::from_le_bytes(next_ix.data[0..4].try_into().unwrap());
        if ix_type != 2 {
            return err!(ErrorCode::InvalidTransferData);
        }

        let transfer_amount = u64::from_le_bytes(next_ix.data[4..12].try_into().unwrap());

        // 5. Verify amounts match
        if transfer_amount != amount {
            return err!(ErrorCode::PolicyViolation);
        }

        Ok(())
    }
}

#[derive(Accounts)]
pub struct InitializePolicy<'info> {
    #[account(
        init,
        payer = authority,
        space = 8 + 8 + 32,
        seeds = [b"policy", authority.key().as_ref()],
        bump
    )]
    pub policy: Account<'info, VoicePolicy>,
    #[account(mut)]
    pub authority: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct CheckVerifiableIntent<'info> {
    #[account(
        seeds = [b"policy", authority.key().as_ref()],
        bump,
        has_one = authority
    )]
    pub policy: Account<'info, VoicePolicy>,
    pub authority: Signer<'info>,
    /// CHECK: This is the instructions sysvar
    #[account(address = anchor_lang::solana_program::sysvar::instructions::ID)]
    pub instructions_sysvar: AccountInfo<'info>,
}

#[account]
pub struct VoicePolicy {
    pub max_amount: u64,
    pub authority: Pubkey,
}

#[error_code]
pub enum ErrorCode {
    #[msg("Amount exceeds policy limits or intent mismatch.")]
    PolicyViolation,
    #[msg("The transfer instruction is missing.")]
    MissingTransferInstruction,
    #[msg("The next instruction must be a system transfer.")]
    InvalidNextInstruction,
    #[msg("Invalid transfer instruction data.")]
    InvalidTransferData,
}
