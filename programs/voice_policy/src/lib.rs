use anchor_lang::prelude::*;
use anchor_lang::solana_program::sysvar::instructions::{load_instruction_at_checked, load_current_index_checked};

declare_id!("Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS");

#[program]
pub mod voice_policy {
    use super::*;

    pub fn initialize_policy(
        ctx: Context<InitializePolicy>, 
        limit_amount: u64, 
        whitelisted_destinations: Vec<Pubkey>
    ) -> Result<()> {
        let policy = &mut ctx.accounts.voice_policy;
        policy.authority = ctx.accounts.authority.key();
        policy.limit_amount = limit_amount;
        policy.whitelisted_destinations = whitelisted_destinations;
        Ok(())
    }

    pub fn check_verifiable_intent(ctx: Context<CheckVerifiableIntent>) -> Result<()> {
        let policy = &ctx.accounts.voice_policy;
        let instructions_sysvar = &ctx.accounts.instructions;

        let current_index = load_current_index_checked(&instructions_sysvar.to_account_info())?;
        
        // As a Security Middleware, this instruction should ideally be near the start of the transaction.
        // We will introspect all instructions in the transaction to ensure no policies are violated.
        let mut i = 0;
        loop {
            if i == current_index {
                i += 1;
                continue; // Skip our own instruction
            }
            
            let ix = match load_instruction_at_checked(i as usize, &instructions_sysvar.to_account_info()) {
                Ok(ix) => ix,
                Err(anchor_lang::solana_program::program_error::ProgramError::InvalidArgument) => break, // Reached end of instructions
                Err(e) => return Err(e.into()),
            };

            // Generic Instruction Discriminator matching pattern
            match ix.program_id {
                // 1. System Program (Native SOL)
                anchor_lang::system_program::ID => {
                    if ix.data.len() >= 4 {
                        let discriminator = &ix.data[0..4];
                        
                        // System Program Transfer Discriminator is 2 (encoded as u32 little-endian [2, 0, 0, 0])
                        if discriminator == [2, 0, 0, 0] && ix.data.len() >= 12 {
                            let mut lamports_data = [0u8; 8];
                            lamports_data.copy_from_slice(&ix.data[4..12]);
                            let lamports = u64::from_le_bytes(lamports_data);

                            if ix.accounts.len() > 1 {
                                let recipient = ix.accounts[1].pubkey;
                                require!(lamports <= policy.limit_amount, PolicyError::AmountExceedsLimit);
                                require!(policy.whitelisted_destinations.contains(&recipient), PolicyError::DestinationNotWhitelisted);
                            }
                        }
                    }
                },
                
                // 2. SPL Token Program
                // id => if id == spl_token::ID { ... }
                // For a commercial SDK, we structure it so SPL Token checks can easily be added.
                // Token Program Transfer Discriminator is 3 (u8). TransferChecked is 12 (u8).
                /*
                spl_token::ID => {
                    if ix.data.len() >= 1 {
                        let discriminator = ix.data[0];
                        match discriminator {
                            // Transfer
                            3 => { ... parse amount and destination ... },
                            // TransferChecked
                            12 => { ... parse amount and destination ... },
                            _ => {}
                        }
                    }
                },
                */

                // Ignore other programs or add a strict mode to fail on unknown programs
                _ => {}
            }

            i += 1;
        }

        Ok(())
    }
}

#[derive(Accounts)]
pub struct InitializePolicy<'info> {
    #[account(
        init, 
        payer = authority, 
        space = 8 + 32 + 8 + 4 + (32 * 10), // Example max space: 10 pubkeys in vec
        seeds = [b"voice_policy", authority.key().as_ref()], 
        bump
    )]
    pub voice_policy: Account<'info, VoicePolicy>,
    
    #[account(mut)]
    pub authority: Signer<'info>,
    
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct CheckVerifiableIntent<'info> {
    #[account(
        seeds = [b"voice_policy", authority.key().as_ref()], 
        bump
    )]
    pub voice_policy: Account<'info, VoicePolicy>,
    
    /// CHECK: The user's wallet signing the transaction. The PDA acts as Security Middleware.
    pub authority: Signer<'info>,

    /// CHECK: Instructions sysvar
    #[account(address = anchor_lang::solana_program::sysvar::instructions::ID)]
    pub instructions: UncheckedAccount<'info>,
}

#[account]
pub struct VoicePolicy {
    pub authority: Pubkey,
    pub limit_amount: u64,
    pub whitelisted_destinations: Vec<Pubkey>,
}

#[error_code]
pub enum PolicyError {
    #[msg("Transfer amount exceeds the voice policy limit.")]
    AmountExceedsLimit,
    #[msg("Destination address is not whitelisted in the voice policy.")]
    DestinationNotWhitelisted,
}
