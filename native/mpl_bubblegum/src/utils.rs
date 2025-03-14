use solana_sdk::{bs58, pubkey::Pubkey};

pub trait FromStrConst {
    fn from_str_const(s: &str) -> Self;
}

impl FromStrConst for Pubkey {
    fn from_str_const(s: &str) -> Self {
        Pubkey::try_from(s).expect("Error: Invalid public key string.")
    }
}

pub fn decode_proof(base58_strings: Vec<String>) -> Vec<[u8; 32]> {
    let mut result = Vec::with_capacity(base58_strings.len());

    for base58_string in base58_strings {
        // Decode from base58
        let bytes = bs58::decode(&base58_string)
            .into_vec()
            .map_err(|e| format!("Error: Failed to decode the Base58 string. '{}': {}", base58_string, e))
            .unwrap();

        // Convert to fixed-size array
        let mut array = [0u8; 32];
        array.copy_from_slice(&bytes);

        result.push(array);
    }

    result
}