defmodule MplBubblegum.Mint do
  @moduledoc """
  Functions for minting compressed NFTs on Solana.

  ## Overview

  Compressed NFTs (cNFTs) use Solana's state compression feature to store NFT data
  off-chain while maintaining the security guarantees of the blockchain. This results
  in significantly lower costs compared to traditional NFTs.

  ## Requirements

  Before minting, ensure you have:

  1. Established a connection using `MplBubblegum.Connection.create_connection/2`
  2. Created a Merkle tree account to store your compressed NFTs
  3. Sufficient SOL in your wallet to cover transaction fees

  ## Example Usage

  ```elixir
  # First establish a connection
  MplBubblegum.Connection.create_connection(secret_key, rpc_url)

  # Then mint a compressed NFT
  signature = MplBubblegum.Mint.mint_v1(
    "merkle_tree_address",
    "My NFT",
    "MNFT",
    "https://arweave.net/my-metadata-uri",
    "creator_address",
    "100"  # 100% royalty to the creator
  )
  ```
  """
  alias MplBubblegum.Connection
  alias MplBubblegum.RPC

  @doc """
  Mints a new compressed NFT and returns the transaction signature.

  ## Parameters

  * `merkle_tree` - The address of the Merkle tree account as a base58 string
  * `name` - The name of the NFT
  * `symbol` - The symbol/ticker of the NFT collection
  * `uri` - The URI pointing to the NFT's metadata JSON file (typically on Arweave)
  * `basis` - The creator's wallet address as a base58 string
  * `share` - The creator's royalty share as a string (e.g., "100" for 100%)

  ## Returns

  * `binary()` - The transaction signature as a base58 string

  ## Error Handling

  May raise errors in the following cases:

  * Connection not established
  * Invalid Merkle tree address
  * Transaction failure
  * Network issues

  ## Examples

  ```elixir
  signature = MplBubblegum.Mint.mint_v1(
    "9WzDXyMrFftHVK4jBUEcqABUVVjLPCT9keST9ycxL22F",  # Merkle tree address
    "Awesome NFT",                                    # NFT name
    "ANFT",                                           # Symbol
    "https://arweave.net/abc123",                     # Metadata URI
    "DEF456GHI789jklMNOpqrSTUvwxYZ",                  # Creator address
    "100"                                             # 100% royalty
  )
  ```
  """
  @spec mint_v1(binary(), binary(), binary(), binary(), binary(), binary()) :: binary()
  def mint_v1(merkle_tree, name, symbol, uri, basis, share) do
    # Get the secret key, will raise error if connection not established
    key = try do
      Connection.get_secret_key()
    rescue
      e in RuntimeError ->
        raise RuntimeError, """
        Connection not established!

        #{e.message}

        Please call MplBubblegum.Connection.create_connection/2 before minting.
        """
    end

    # Build the mint transaction
    tx_hash = try do
      MplBubblegum.mint_v1_builder(
        key,
        merkle_tree,
        name,
        symbol,
        uri,
        basis,
        share
      )
    rescue
      e ->
        raise RuntimeError, """
        Failed to build mint transaction!

        Error: #{inspect(e)}

        Please verify all parameters are correct:
        - merkle_tree: Must be a valid Merkle tree address
        - name: Name for the NFT
        - symbol: Symbol for the NFT collection
        - uri: Metadata URI (e.g., Arweave link)
        - basis: Creator wallet address
        - share: Creator royalty percentage as string (e.g., "100")
        """
    end

    # Send the transaction
    case RPC.send_transaction(tx_hash) do
      {:ok, signature} ->
        signature
      {:error, reason} ->
        raise RuntimeError, """
        Mint transaction failed!

        Error: #{inspect(reason)}

        Common causes:
        1. Insufficient SOL balance for transaction fees
        2. Invalid Merkle tree address
        3. Network congestion or RPC issues

        Please check your wallet balance and verify the Merkle tree address.
        """
    end
  end
end
