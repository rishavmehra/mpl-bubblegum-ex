# MplBubblegum

[![Hex.pm](https://img.shields.io/hexpm/v/mpl_bubblegum_exs.svg)](https://hex.pm/packages/mpl_bubblegum_exs)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/mpl_bubblegum_exs)
[![License](https://img.shields.io/hexpm/l/mpl_bubblegum_exs.svg)](https://github.com/rishavmehra/mpl-bubblegum-ex/blob/master/LICENSE)

A comprehensive Elixir library for working with compressed NFTs (cNFTs) on Solana using the Metaplex Bubblegum protocol.

DOCS => 

## Overview

Compressed NFTs (cNFTs) offer significant cost savings over traditional NFTs by leveraging Solana's state compression feature. MplBubblegum provides a simple API to:

- Create Merkle trees for storing compressed NFTs
- Mint new compressed NFTs
- Transfer compressed NFTs between wallets
- Query compressed NFT data

This library provides Elixir bindings to the Solana programs needed for working with compressed NFTs, with most of the heavy lifting implemented in Rust using NIFs for maximum performance.

## Installation

1. Add `mpl_bubblegum_exs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mpl_bubblegum_exs, "~> 0.1.0"}
  ]
end
```

2. Ensure you have Rust installed on your system for compiling the NIFs:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

3. Install the hex package:

```bash
mix deps.get
```

## Requirements

- Elixir 1.17 or later
- Erlang/OTP 25 or later
- Rust 1.85 or later (for compiling NIFs)
- A Helius RPC URL or office one

## Quick Start

### Setting up a Connection

Before using any functionality, establish a connection to a Solana RPC endpoint:

```elixir
# Initialize with your wallet's secret key and Helius RPC URL
secret_key = "your_wallet_private_key" 
rpc_url = "https://your-helius-rpc-endpoint.helius.xyz/..."

MplBubblegum.create_connection(secret_key, rpc_url)
```

> **IMPORTANT**: You must use a Helius RPC URL that supports the Digital Asset Standard (DAS) API for compressed NFT operations. Standard Solana RPC endpoints will not work.

### Creating a Merkle Tree

Create a tree to store your compressed NFTs:

```elixir
# Create a new Merkle tree for storing cNFTs
merkle_tree_address = MplBubblegum.create_tree_config()

# The returned address can now be used for minting
```

### Minting a Compressed NFT

Mint a new compressed NFT into your Merkle tree:

```elixir
# Mint a compressed NFT
signature = MplBubblegum.mint_v1(
  merkle_tree_address,  # The Merkle tree address from create_tree_config
  "My Awesome NFT",     # NFT name
  "MANFT",              # Symbol
  "https://arweave.net/your-metadata-json-uri",  # Metadata URI
  "your_wallet_address",  # Creator address
  "100"                   # 100% royalty to creator
)

# The signature can be used to view the transaction on Solana Explorer
# https://explorer.solana.com/tx/<signature>
```

### Transferring a Compressed NFT

Transfer a compressed NFT to another wallet:

```elixir
# Transfer the NFT to another wallet
recipient = "recipient_wallet_address"  # The recipient's wallet address
asset_id = "compressed_nft_asset_id"    # The asset ID of the NFT to transfer

signature = MplBubblegum.transfer(asset_id, recipient)
```

## Advanced Usage

For more complex operations, you can use the module-specific functions:

### Connection Management

```elixir
alias MplBubblegum.Connection

# Create a connection
Connection.create_connection(secret_key, rpc_url)

# Get the stored secret key
key = Connection.get_secret_key()

# Get the stored RPC URL
url = Connection.get_rpc_url()
```

### Tree Operations

```elixir
alias MplBubblegum.Tree

# Create a Merkle tree with default parameters
tree_address = Tree.create_tree_config()
```

### Minting Operations

```elixir
alias MplBubblegum.Mint

# Mint a compressed NFT 
signature = Mint.mint_v1(
  merkle_tree,
  name,
  symbol, 
  uri,
  creator_address,
  royalty_share
)
```

### Transfer Operations

```elixir
alias MplBubblegum.Transfer

# Transfer a compressed NFT to a new owner
signature = Transfer.transfer(asset_id, recipient_address)
```

### RPC Operations

```elixir
alias MplBubblegum.RPC

# Send a transaction
{:ok, signature} = RPC.send_transaction(serialized_transaction)

# Get asset data
{:ok, asset_data} = RPC.get_asset_data(asset_id) 

# Get asset proof
{:ok, proof_data} = RPC.get_asset_proof(asset_id)
```

## Cost Comparison: Traditional NFTs vs. Compressed NFTs

| Operation            | Traditional NFT | Compressed NFT | Savings |
|----------------------|-----------------|----------------|---------|
| One-time setup       | 0 SOL           | ~0.01 SOL      | -0.01 SOL |
| Mint cost (per NFT)  | ~0.01 SOL       | ~0.000005 SOL  | 99.95%  |
| Storage cost (10K NFTs) | ~100 SOL     | ~0.1 SOL       | 99.9%   |

## Metadata Structure

When creating NFT metadata for your URI JSON, follow this structure:

```json
{
  "name": "My NFT Name",
  "symbol": "SYMBOL",
  "description": "Description of my NFT",
  "image": "https://arweave.net/image-uri",
  "animation_url": "https://arweave.net/animation-uri",
  "external_url": "https://example.com",
  "attributes": [
    { "trait_type": "Background", "value": "Blue" },
    { "trait_type": "Eyes", "value": "Green" }
  ],
  "properties": {
    "files": [
      {
        "uri": "https://arweave.net/image-uri",
        "type": "image/png"
      }
    ],
    "category": "image",
    "creators": [
      {
        "address": "creator_wallet_address",
        "share": 100
      }
    ]
  }
}
```

## Error Handling

MplBubblegum uses descriptive error messages to help diagnose issues:

```elixir
try do
  MplBubblegum.mint_v1(merkle_tree, name, symbol, uri, creator, royalty)
rescue
  e in RuntimeError ->
    # Handle the error
    IO.puts("Error: #{e.message}")
end
```

## Development

### Building from Source

1. Clone the repository:

```bash
git clone https://github.com/rishavmehra/mpl-bubblegum-ex.git
cd mpl-bubblegum-ex
```

2. Install dependencies:

```bash
mix deps.get
```

3. Compile the project:

```bash
mix compile
```

### Running Tests

```bash
mix test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgements

- [Metaplex Foundation](https://metaplex.com/) for the Bubblegum protocol
- [Solana Labs](https://solana.com/) for the Solana blockchain
- [Helius](https://helius.xyz/) for providing DAS API support