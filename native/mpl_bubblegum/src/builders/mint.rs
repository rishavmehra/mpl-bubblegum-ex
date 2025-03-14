use base64;
use mpl_bubblegum::{
    instructions::{MintV1, MintV1InstructionArgs},
    types::{Creator, TokenProgramVersion, TokenStandard},
};
use solana_client::rpc_client::RpcClient;
use solana_sdk::{
    bs58,
    instruction::{AccountMeta, Instruction},
    pubkey,
    pubkey::Pubkey,
    signature::Keypair,
    signer::Signer,
    system_program,
    transaction::Transaction,
};

pub fn mint_v1_builder(
    payer_secret_key: String,
    merkle_tree: String,
    name: String,
    symbol: String,
    uri: String,
    seller_fee_basis_points: u16,
    share: u8,
) -> String {
    let rpc_url = "https://api.devnet.solana.com".to_string();
    let client = RpcClient::new(rpc_url);
    let secret_key_bytes = bs58::decode(payer_secret_key)
        .into_vec()
        .expect("Error: Failed to decode the secret key.");
    let payer = Keypair::from_bytes(&secret_key_bytes).expect("Error: Invalid secret key.");
    let merkle_tree = Pubkey::from_str_const(&merkle_tree);
    let (tree_config, _) = Pubkey::find_program_address(
        &[merkle_tree.as_array()],
        &pubkey!("BGUMAp9Gq7iTEuizy4pqaxsTyUCBK68MDfK752saRPUY"),
    );
    let mint_ix_accounts = mpl_bubblegum::types::MetadataArgs {
        name,
        symbol,
        uri,
        seller_fee_basis_points,
        primary_sale_happened: false,
        is_mutable: false,
        edition_nonce: None,
        token_standard: Some(TokenStandard::NonFungible),
        collection: None,
        uses: None,
        token_program_version: TokenProgramVersion::Original,
        creators: vec![Creator {
            address: payer.pubkey().to_bytes().into(),
            verified: true,
            share,
        }],
    };

    let mint_ix = MintV1 {
        tree_config: tree_config.to_bytes().into(),
        leaf_owner: payer.pubkey().to_bytes().into(),
        leaf_delegate: payer.pubkey().to_bytes().into(),
        merkle_tree: merkle_tree.to_bytes().into(),
        payer: payer.pubkey().to_bytes().into(),
        tree_creator_or_delegate: payer.pubkey().to_bytes().into(),
        log_wrapper: pubkey!("noopb9bkMVfRPU8AsbpTUg8AQkHtKwMYZiFUjNRtMmV")
            .to_bytes()
            .into(),
        compression_program: spl_account_compression::ID.to_bytes().into(),
        system_program: system_program::ID.to_bytes().into(),
    };
    let mint_ix = mint_ix.instruction(MintV1InstructionArgs {
        metadata: mint_ix_accounts,
    });
    let mint_ix = Instruction {
        program_id: mint_ix.program_id.to_bytes().into(),
        accounts: mint_ix
            .accounts
            .iter()
            .map(|meta| AccountMeta {
                pubkey: meta.pubkey.to_bytes().into(),
                is_signer: meta.is_signer,
                is_writable: meta.is_writable,
            })
            .collect(),
        data: mint_ix.data,
    };
    let recent_blockhash = client.get_latest_blockhash().unwrap();
    let tx = Transaction::new_signed_with_payer(
        &[mint_ix],
        Some(&payer.pubkey()),
        &[&payer],
        recent_blockhash.to_bytes().into(),
    );
    let serialized_tx = bincode::serialize(&tx).expect("Error: Failed to serialize the transaction");
    base64::encode(serialized_tx)
}