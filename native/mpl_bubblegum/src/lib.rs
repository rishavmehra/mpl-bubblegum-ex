use rustler::nif;

mod builders;
mod utils;

#[nif(schedule = "DirtyIo")]
fn create_tree_config_builder(payer_secret_key: String) -> Vec<String> {
    builders::tree::create_tree_config_builder(payer_secret_key)
}

#[nif(schedule = "DirtyIo")]
fn mint_v1_builder(
    payer_secret_key: String,
    merkle_tree: String,
    name: String,
    symbol: String,
    uri: String,
    seller_fee_basis_points: u16,
    share: u8,
) -> String {
    builders::mint::mint_v1_builder(
        payer_secret_key,
        merkle_tree,
        name,
        symbol,
        uri,
        seller_fee_basis_points,
        share,
    )
}

#[nif(schedule = "DirtyIo")]
pub fn transfer_builder(
payer_secret_key: String,
to_address: String,
asset_id: String,
nonce: u64,
data_hash: String,
creator_hash: String,
root: String,
proof: Vec<String>,
merkle_tree: String,
) -> Result<String, String> {
// Call the implementation function with appropriate Option wrappers
builders::transfer::transfer_builder(
    payer_secret_key,
    to_address,
    Some(asset_id),
    Some(nonce),
    Some(data_hash),
    Some(creator_hash),
    Some(root),
    Some(proof),
    Some(merkle_tree),
    None,           // tree_config
    Some(nonce as u32), // index - using nonce as index like in original code
    None,           // leaf_owner
    None,           // leaf_delegate
    None,           // das_get_asset_proof
    None,           // das_get_asset
)
}


rustler::init!("Elixir.MplBubblegum");