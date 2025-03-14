use base64;
use mpl_bubblegum::instructions::TransferBuilder;
use solana_client::rpc_client::RpcClient;
use solana_program::{
    instruction::AccountMeta as ProgramAccountMeta,
    pubkey::Pubkey as ProgramPubkey,
};
use solana_sdk::{
    bs58,
    instruction::{AccountMeta, Instruction},
    pubkey::Pubkey as SdkPubkey,
    signature::Keypair,
    signer::Signer,
    transaction::Transaction,
};
use std::str::FromStr;

use crate::utils::decode_proof;

pub fn transfer_builder(
    payer_secret_key: String,
    new_leaf_owner: String,
    asset_id: Option<String>,
    leaf_id: Option<u64>,
    data_hash: Option<String>,
    creator_hash: Option<String>,
    root: Option<String>,
    proof: Option<Vec<String>>,
    merkle_tree: Option<String>,
    tree_config: Option<String>,
    index: Option<u32>,
    leaf_owner: Option<String>,
    leaf_delegate: Option<String>,
    das_get_asset_proof: Option<String>,
    das_get_asset: Option<String>,
) -> Result<String, String> {
    let rpc_url = "https://api.devnet.solana.com".to_string();
    let client = RpcClient::new(rpc_url);
    
    // Parse the payer keypair
    let secret_key_bytes = bs58::decode(payer_secret_key)
        .into_vec()
        .map_err(|e| format!("Failed to decode secret key: {}", e))?;
    let payer = Keypair::from_bytes(&secret_key_bytes)
        .map_err(|e| format!("Not a valid secret key: {}", e))?;

    // Parse the new leaf owner pubkey
    let new_leaf_owner = SdkPubkey::from_str(&new_leaf_owner)
        .map_err(|_| "Invalid new_leaf_owner pubkey string".to_string())?;
    let new_leaf_owner_program = ProgramPubkey::new_from_array(new_leaf_owner.to_bytes());

    // Determine who is signing
    let delegate_is_signing = leaf_delegate.is_some();
    
    // Setup leaf owner and leaf delegate
    let leaf_owner_pubkey = match leaf_owner {
        Some(key) => SdkPubkey::from_str(&key)
            .map_err(|_| "Invalid leaf_owner pubkey string".to_string())?,
        None => payer.pubkey(),
    };
    let leaf_owner_program = ProgramPubkey::new_from_array(leaf_owner_pubkey.to_bytes());
    
    let leaf_delegate_pubkey = match leaf_delegate {
        Some(key) => SdkPubkey::from_str(&key)
            .map_err(|_| "Invalid leaf_delegate pubkey string".to_string())?,
        None => leaf_owner_pubkey,
    };
    let leaf_delegate_program = ProgramPubkey::new_from_array(leaf_delegate_pubkey.to_bytes());

    // Process proof - assuming decode_proof handles the parsing of proof strings
    let proof_vec = match proof {
        Some(proof_data) => proof_data,
        None => {
            if let Some(_) = das_get_asset_proof {
                // In a real implementation, you would parse the JSON here
                // For now, just return an error since we need the proof
                return Err("Proof extraction from DAS response not implemented".to_string());
            } else {
                return Err("proof is required".to_string());
            }
        },
    };

    let proof_accounts: Vec<AccountMeta> = decode_proof(proof_vec.clone())
        .iter()
        .map(|hash| AccountMeta::new_readonly(SdkPubkey::new_from_array(*hash), false))
        .collect();

    let proof_accounts_program: Vec<ProgramAccountMeta> = decode_proof(proof_vec)
        .iter()
        .map(|hash| ProgramAccountMeta {
            pubkey: ProgramPubkey::new_from_array(*hash),
            is_signer: false,
            is_writable: false,
        })
        .collect();

    // Get root
    let root_bytes: [u8; 32] = match root {
        Some(r) => bs58::decode(&r)
            .into_vec()
            .map_err(|_| "Invalid root string".to_string())?
            .try_into()
            .map_err(|_| "Invalid root length".to_string())?,
        None => {
            // In a real implementation, you would parse the JSON here
            return Err("root is required".to_string());
        },
    };

    // Get data hash
    let data_hash_bytes: [u8; 32] = match data_hash {
        Some(dh) => bs58::decode(&dh)
            .into_vec()
            .map_err(|_| "Invalid data_hash string".to_string())?
            .try_into()
            .map_err(|_| "Invalid data_hash length".to_string())?,
        None => {
            // In a real implementation, you would parse the JSON here
            return Err("data_hash is required".to_string());
        },
    };

    // Get creator hash
    let creator_hash_bytes: [u8; 32] = match creator_hash {
        Some(ch) => bs58::decode(&ch)
            .into_vec()
            .map_err(|_| "Invalid creator_hash string".to_string())?
            .try_into()
            .map_err(|_| "Invalid creator_hash length".to_string())?,
        None => {
            // In a real implementation, you would parse the JSON here
            return Err("creator_hash is required".to_string());
        },
    };

    // Get nonce (leaf_id)
    let nonce = match leaf_id {
        Some(id) => id,
        None => return Err("leaf_id is required".to_string()),
    };

    // Get index
    let index_value = match index {
        Some(idx) => idx,
        None => return Err("index is required".to_string()),
    };

    // Get merkle tree
    let merkle_tree_pubkey = match merkle_tree {
        Some(mt) => SdkPubkey::from_str(&mt)
            .map_err(|_| "Invalid merkle_tree pubkey string".to_string())?,
        None => return Err("merkle_tree is required".to_string()),
    };
    let merkle_tree_program = ProgramPubkey::new_from_array(merkle_tree_pubkey.to_bytes());

    // Get tree config
    let tree_config_program = match tree_config {
        Some(tc) => {
            let tree_config_sdk = SdkPubkey::from_str(&tc)
                .map_err(|_| "Invalid tree_config pubkey string".to_string())?;
            ProgramPubkey::new_from_array(tree_config_sdk.to_bytes())
        },
        None => {
            // Convert SDK pubkey to Program pubkey for find_pda
            mpl_bubblegum::accounts::TreeConfig::find_pda(&merkle_tree_program).0
        },
    };

    // Build the transfer instruction
    let transfer_ix = TransferBuilder::new()
        .new_leaf_owner(new_leaf_owner_program)
        .tree_config(tree_config_program)
        .leaf_owner(leaf_owner_program, !delegate_is_signing)
        .leaf_delegate(leaf_delegate_program, delegate_is_signing)
        .merkle_tree(merkle_tree_program)
        .root(root_bytes)
        .data_hash(data_hash_bytes)
        .creator_hash(creator_hash_bytes)
        .nonce(nonce)
        .index(index_value)
        .add_remaining_accounts(&proof_accounts_program)
        .instruction();

    // Convert program instruction to SDK instruction
    let sdk_ix = Instruction {
        program_id: SdkPubkey::new_from_array(transfer_ix.program_id.to_bytes()),
        accounts: transfer_ix.accounts.iter().map(|meta| AccountMeta {
            pubkey: SdkPubkey::new_from_array(meta.pubkey.to_bytes()),
            is_signer: meta.is_signer,
            is_writable: meta.is_writable,
        }).collect(),
        data: transfer_ix.data,
    };

    // Create the transaction
    let recent_blockhash = client.get_latest_blockhash()
        .map_err(|e| format!("Failed to get recent blockhash: {}", e))?;

    // Convert the program blockhash to SDK blockhash
    let sdk_recent_blockhash = solana_sdk::hash::Hash::new_from_array(recent_blockhash.to_bytes());

    let tx = Transaction::new_signed_with_payer(
        &[sdk_ix],
        Some(&payer.pubkey()),
        &[&payer],
        sdk_recent_blockhash,
    );

    // Serialize the transaction
    let serialized_tx = bincode::serialize(&tx)
        .map_err(|e| format!("Failed to serialize transaction: {}", e))?;
    
    Ok(base64::encode(serialized_tx))
}