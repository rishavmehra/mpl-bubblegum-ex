defmodule MplBubblegum do
  @moduledoc """
  A comprehensive Elixir library for working with compressed NFTs (cNFTs) on Solana.

  ## Overview

  MplBubblegum provides tools to create, mint, and transfer compressed NFTs on Solana
  using the Metaplex Bubblegum protocol. Compressed NFTs offer significant cost savings
  over traditional NFTs by leveraging Solana's state compression feature.

  ## Installation

  Add `mpl_bubblegum_lib` to your mix.exs dependencies:

  ```elixir
  def deps do
    [
      {:mpl_bubblegum_lib, "~> 0.1.0"}
    ]
  end
  ```

  Published on Hex.pm: [https://hex.pm/packages/mpl_bubblegum_nifs](https://hex.pm/packages/mpl_bubblegum_nifs)

  ## Requirements

  * Elixir 1.14 or later
  * Erlang/OTP 25 or later
  * A Helius RPC URL (standard Solana RPC does not support DAS API)

  ## Getting Started

  The typical workflow for using compressed NFTs is:

  1. **Setup Connection** - Initialize a connection with your wallet and RPC URL
  2. **Create Merkle Tree** - Create an on-chain Merkle tree to store your NFTs
  3. **Mint NFTs** - Mint compressed NFTs into your Merkle tree
  4. **Transfer NFTs** - Transfer NFTs to other wallets as needed

  ## Example Usage

  ```elixir
  # 1. Set up connection
  secret_key = "your_wallet_private_key"
  rpc_url = "https://your-helius-rpc-endpoint.helius.xyz/..."
  MplBubblegum.create_connection(secret_key, rpc_url)

  # 2. Create a Merkle tree
  merkle_tree = MplBubblegum.create_tree_config()

  # 3. Mint a compressed NFT
  name = "My Awesome NFT"
  symbol = "MANFT"
  uri = "https://arweave.net/your-metadata-json-uri"
  creator = "your_wallet_address"
  royalty_share = "100"  # 100% royalty to creator

  signature = MplBubblegum.mint_v1(merkle_tree, name, symbol, uri, creator, royalty_share)

  # 4. Transfer an NFT to another wallet
  recipient = "recipient_wallet_address"
  asset_id = "compressed_nft_asset_id"

  signature = MplBubblegum.transfer(asset_id, recipient)
  ```

  ## Module Structure

  This library is organized into several modules:

  * `MplBubblegum` - Main module with re-exported functions for simplicity
  * `MplBubblegum.Connection` - Connection management
  * `MplBubblegum.Tree` - Merkle tree creation and management
  * `MplBubblegum.Mint` - Functionality for minting compressed NFTs
  * `MplBubblegum.Transfer` - Functionality for transferring compressed NFTs
  * `MplBubblegum.RPC` - Low-level RPC communication with Solana

  ## Native Implementation

  The core functionality is implemented in Rust using Rustler NIFs,
  which provide high performance and direct access to Solana's cryptographic
  primitives and transaction building logic.
  """
  use Rustler, otp_app: :mpl_bubblegum_lib, crate: "mpl_bubblegum"

  # Define the NIF functions here
  @doc """
  Creates a Merkle tree configuration transaction.

  This is a low-level NIF function that builds a transaction for creating
  a Merkle tree. Most users should use `create_tree_config/0` instead.

  ## Parameters

  * `secret_key` - Your wallet's secret key

  ## Returns

  * `[serialized_transaction, merkle_tree_address]` - A list containing the
    serialized transaction and the new Merkle tree address

  ## Error Handling

  Will raise a NIF-specific error if:
  * The NIF library fails to load
  * The secret key is invalid
  * Transaction creation fails
  """
  @spec create_tree_config_builder(binary()) :: [binary()]
  def create_tree_config_builder(_secret_key) do
    error_message = """
    NIF library not loaded!

    This could be due to:
    1. Missing Rust compiler or build tools
    2. Incompatible architecture
    3. Failed compilation of Rust NIF

    Please ensure you've properly installed the mpl_bubblegum_lib package
    and that your environment supports compiling Rust NIFs.
    """
    :erlang.nif_error(error_message)
  end

  @doc """
  Creates a mint transaction for a compressed NFT.

  This is a low-level NIF function that builds a transaction for minting
  a compressed NFT. Most users should use `mint_v1/6` instead.

  ## Parameters

  * `secret_key` - Your wallet's secret key
  * `merkle_tree` - Address of the Merkle tree
  * `name` - Name of the NFT
  * `symbol` - Symbol/ticker of the NFT collection
  * `uri` - URI pointing to the NFT's metadata JSON
  * `basis` - Creator's wallet address
  * `share` - Creator's royalty share as a string (e.g., "100" for 100%)

  ## Returns

  * `binary()` - The serialized transaction

  ## Error Handling

  Will raise a NIF-specific error if:
  * The NIF library fails to load
  * Any parameter is invalid
  * Transaction creation fails
  """
  @spec mint_v1_builder(binary(), binary(), binary(), binary(), binary(), binary(), binary()) :: binary()
  def mint_v1_builder(_secret_key, _merkle_tree, _name, _symbol, _uri, _basis, _share) do
    error_message = """
    NIF library not loaded!

    This could be due to:
    1. Missing Rust compiler or build tools
    2. Incompatible architecture
    3. Failed compilation of Rust NIF

    Please ensure you've properly installed the mpl_bubblegum_lib package
    and that your environment supports compiling Rust NIFs.
    """
    :erlang.nif_error(error_message)
  end

  @doc """
  Creates a transfer transaction for a compressed NFT.

  This is a low-level NIF function that builds a transaction for transferring
  a compressed NFT. Most users should use `transfer/2` instead.

  ## Parameters

  * `payer_secret_key` - Your wallet's secret key
  * `to_address` - Recipient's wallet address
  * `asset_id` - Asset ID of the compressed NFT
  * `nonce` - Leaf ID in the Merkle tree
  * `data_hash` - Hash of the NFT data
  * `creator_hash` - Hash of the NFT creators
  * `root` - Current root hash of the Merkle tree
  * `proof` - Merkle proof for the NFT
  * `merkle_tree` - Address of the Merkle tree

  ## Returns

  * `binary()` - The serialized transaction

  ## Error Handling

  Will raise a NIF-specific error if:
  * The NIF library fails to load
  * Any parameter is invalid
  * Transaction creation fails
  """
  @spec transfer_builder(
          binary(),
          binary(),
          binary(),
          non_neg_integer(),
          binary(),
          binary(),
          binary(),
          list(binary()),
          binary()
        ) :: binary()
  def transfer_builder(
        _payer_secret_key,
        _to_address,
        _asset_id,
        _nonce,
        _data_hash,
        _creator_hash,
        _root,
        _proof,
        _merkle_tree
      ) do
    error_message = """
    NIF library not loaded!

    This could be due to:
    1. Missing Rust compiler or build tools
    2. Incompatible architecture
    3. Failed compilation of Rust NIF

    Please ensure you've properly installed the mpl_bubblegum_lib package
    and that your environment supports compiling Rust NIFs.
    """
    :erlang.nif_error(error_message)
  end

  # Re-export functions from submodules to maintain the original API

  @doc """
  Creates a new connection with the given secret key and RPC URL.

  See `MplBubblegum.Connection.create_connection/2` for details.
  """
  defdelegate create_connection(secret_key, rpc_url), to: MplBubblegum.Connection

  # Tree functions
  @doc """
  Creates a new Merkle tree configuration.

  See `MplBubblegum.Tree.create_tree_config/0` for details.
  """
  defdelegate create_tree_config(), to: MplBubblegum.Tree

  # Mint functions
  @doc """
  Mints a new compressed NFT.

  See `MplBubblegum.Mint.mint_v1/6` for details.
  """
  defdelegate mint_v1(merkle_tree, name, symbol, uri, basis, share), to: MplBubblegum.Mint

  # Transfer functions
  @doc """
  Transfers a compressed NFT to a new owner.

  See `MplBubblegum.Transfer.transfer/2` for details.
  """
  defdelegate transfer(asset_id, to_address), to: MplBubblegum.Transfer

  # RPC functions
  @doc """
  Sends a transaction to the Solana network.

  See `MplBubblegum.RPC.send_transaction/1` for details.
  """
  defdelegate send_transaction(tx_hash), to: MplBubblegum.RPC
end
