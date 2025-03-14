defmodule MplBubblegum.Tree do
  @moduledoc """
  Functions for managing Merkle tree configurations for compressed NFTs on Solana.

  ## Overview

  This module provides functionality to create and manage Merkle trees, which are
  essential data structures for storing compressed NFTs. The Merkle tree is a
  fundamental component of Solana's state compression feature, allowing thousands
  of NFTs to be stored at a fraction of the cost of traditional NFTs.

  ## Merkle Trees for Compressed NFTs

  Merkle trees in Solana:

  * Act as on-chain storage containers for compressed NFTs
  * Allow for cryptographic verification of NFT ownership and data
  * Significantly reduce the storage costs by keeping most data off-chain
  * Require creation before minting any compressed NFTs

  ## Prerequisites

  Before creating a Merkle tree:

  1. A connection must be established using `MplBubblegum.Connection.create_connection/2`
  2. Your wallet must have sufficient SOL to cover the tree creation cost
     (typically 0.01-0.05 SOL depending on tree size)

  ## Example Usage

  ```elixir
  # First establish a connection with your wallet's private key
  MplBubblegum.Connection.create_connection(secret_key, rpc_url)

  # Then create a new Merkle tree
  merkle_tree_address = MplBubblegum.Tree.create_tree_config()

  # The returned address can now be used for minting compressed NFTs
  ```
  """
  alias MplBubblegum.Connection
  alias MplBubblegum.RPC

  @doc """
  Creates a new Merkle tree configuration for storing compressed NFTs.

  This function creates an on-chain Merkle tree that can store compressed NFTs.
  The creation process involves:

  1. Building a tree configuration transaction
  2. Sending the transaction to the Solana network
  3. Returning the address of the created Merkle tree

  ## Returns

  * `binary()` - The Merkle tree address as a base58 string

  ## Error Handling

  This function will raise errors in the following cases:

  * `RuntimeError` - If no connection has been established
  * `RuntimeError` - If the tree creation transaction fails
  * `RuntimeError` - If there's insufficient SOL to create the tree

  ## Costs

  Creating a Merkle tree requires SOL to cover:

  * The rent-exempt balance for the tree account
  * Transaction fees

  The exact cost depends on the tree's maximum depth and buffer size,
  which determines how many NFTs it can store.

  ## Examples

  ```elixir
  # Create a new Merkle tree
  merkle_tree_address = MplBubblegum.Tree.create_tree_config()

  # Use the tree address for minting compressed NFTs
  signature = MplBubblegum.Mint.mint_v1(
    merkle_tree_address,
    "My NFT",
    "MNFT",
    "https://arweave.net/my-metadata-uri",
    creator_address,
    "100"
  )
  ```
  """
  @spec create_tree_config() :: binary()
  def create_tree_config() do
    # Get the secret key, which will raise an error if connection is not established
    key = try do
      Connection.get_secret_key()
    rescue
      e in RuntimeError ->
        reraise """
        #{e.message}

        You must establish a connection before creating a Merkle tree.
        Example:
          MplBubblegum.Connection.create_connection(secret_key, rpc_url)
        """, __STACKTRACE__
    end

    # Build the tree configuration transaction
    [serialized_tx, merkle_tree] = try do
      MplBubblegum.create_tree_config_builder(key)
    rescue
      e ->
        raise RuntimeError, """
        Failed to build Merkle tree configuration transaction!

        Error: #{inspect(e)}

        This could be due to:
        1. Invalid secret key format
        2. Issues with the internal transaction builder

        Please verify your secret key is valid and try again.
        """
    end

    # Send the transaction to create the tree
    case RPC.send_transaction(serialized_tx) do
      {:ok, _signature} ->
        merkle_tree
      {:error, %{"message" => message} = reason} when is_map(reason) ->
        handle_tree_creation_error(message, reason)
      {:error, reason} ->
        raise RuntimeError, """
        Merkle tree creation transaction failed!

        Error: #{inspect(reason)}

        Common causes:
        1. Insufficient SOL balance for tree creation and transaction fees
        2. Network congestion or RPC issues
        3. Transaction simulation failed

        Please check your wallet balance and try again.
        """
    end
  end

  # Private helper to handle specific tree creation errors
  defp handle_tree_creation_error(message, reason) do
    cond do
      String.contains?(message, "0x1") ->
        raise RuntimeError, """
        Insufficient funds to create Merkle tree!

        Error: #{inspect(reason)}

        Creating a Merkle tree requires SOL for:
        1. The rent-exempt balance for the tree account (typically 0.01-0.05 SOL)
        2. Transaction fee (approximately 0.000005 SOL)

        Please add more SOL to your wallet and try again.
        """

      String.contains?(message, "blockhash") ->
        raise RuntimeError, """
        Transaction failed due to expired blockhash!

        Error: #{inspect(reason)}

        This usually happens when:
        1. The network is congested
        2. There was a delay between building and sending the transaction

        Please try again. If the problem persists, check your
        RPC provider's status or try a different RPC endpoint.
        """

      true ->
        raise RuntimeError, """
        Merkle tree creation failed with unexpected error!

        Error: #{inspect(reason)}

        Please check your connection and wallet status, then try again.
        If the problem persists, contact support with this error message.
        """
    end
  end
end
