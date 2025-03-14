use base64;
use mpl_bubblegum::instructions::{CreateTreeConfig, CreateTreeConfigInstructionArgs};
use solana_client::rpc_client::RpcClient;
use solana_sdk::{
    bs58,
    instruction::{AccountMeta, Instruction},
    pubkey,
    pubkey::Pubkey,
    signature::Keypair,
    signer::Signer,
    system_instruction, system_program,
    transaction::Transaction,
};
use spl_account_compression::{state::CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1, ConcurrentMerkleTree};

pub fn create_tree_config_builder(payer_secret_key: String) -> Vec<String> {
    const MAX_DEPTH: usize = 14;
    const MAX_BUFFER_SIZE: usize = 64;
    let secret_key_bytes = bs58::decode(payer_secret_key)
        .into_vec()
        .expect("Error: Failed to decode the secret key.");
    let payer = Keypair::from_bytes(&secret_key_bytes).expect("Error: Invalid secret key.");
    let merkle_tree = Keypair::new();
    let (tree_config, _) = Pubkey::find_program_address(
        &[merkle_tree.pubkey().as_array()],
        &pubkey!("BGUMAp9Gq7iTEuizy4pqaxsTyUCBK68MDfK752saRPUY"),
    );
    let rpc_url = "https://api.devnet.solana.com".to_string();
    let client = RpcClient::new(rpc_url);
    let size = CONCURRENT_MERKLE_TREE_HEADER_SIZE_V1
        + std::mem::size_of::<ConcurrentMerkleTree<MAX_DEPTH, MAX_BUFFER_SIZE>>();
    let rent = client.get_minimum_balance_for_rent_exemption(size).unwrap();
    let create_merkle_ix: Instruction = system_instruction::create_account(
        &payer.pubkey().to_bytes().into(),
        &merkle_tree.pubkey().to_bytes().into(),
        rent,
        size as u64,
        &spl_account_compression::ID.to_bytes().into(),
    );
    let create_tree_accounts = CreateTreeConfigInstructionArgs {
        max_depth: MAX_DEPTH as u32,
        max_buffer_size: MAX_BUFFER_SIZE as u32,
        public: Some(false),
    };
    let create_config_ix = CreateTreeConfig {
        tree_config: tree_config.to_bytes().into(),
        merkle_tree: merkle_tree.pubkey().to_bytes().into(),
        payer: payer.pubkey().to_bytes().into(),
        tree_creator: payer.pubkey().to_bytes().into(),
        log_wrapper: pubkey!("noopb9bkMVfRPU8AsbpTUg8AQkHtKwMYZiFUjNRtMmV")
            .to_bytes()
            .into(),
        compression_program: spl_account_compression::ID.to_bytes().into(),
        system_program: system_program::ID.to_bytes().into(),
    }
    .instruction(create_tree_accounts);
    let create_config_ix: Instruction = Instruction {
        program_id: create_config_ix.program_id.to_bytes().into(),
        accounts: create_config_ix
            .accounts
            .iter()
            .map(|meta| AccountMeta {
                pubkey: meta.pubkey.to_bytes().into(),
                is_signer: meta.is_signer,
                is_writable: meta.is_writable,
            })
            .collect(),
        data: create_config_ix.data,
    };
    let recent_blockhash = client.get_latest_blockhash().unwrap();
    let tx = Transaction::new_signed_with_payer(
        &[create_merkle_ix, create_config_ix],
        Some(&payer.pubkey()),
        &[&merkle_tree, &payer],
        recent_blockhash.to_bytes().into(),
    );
    let serialized_tx = bincode::serialize(&tx).expect("Error: Failed to serialize the transaction.");
    vec![
        base64::encode(serialized_tx),
        merkle_tree.pubkey().to_string(),
    ]
}