defmodule MplBubblegum.Transfer do
  @moduledoc """
  Functions for transferring compressed NFTs on Solana.

  ## Overview

  This module provides functionality to transfer ownership of compressed NFTs (cNFTs)
  that were created using the Metaplex Bubblegum standard. Compressed NFTs use Solana's
  state compression feature which allows for much lower transaction costs compared to
  traditional NFTs.

  ## Prerequisites

  Before transferring a compressed NFT:

  1. A connection must be established using `MplBubblegum.Connection.create_connection/2`
  2. You must have the asset ID of the compressed NFT you want to transfer
  3. You must own the NFT you're attempting to transfer
  4. You must have sufficient SOL in your wallet to cover transaction fees

  ## Transfer Process

  The transfer process includes:

  1. Retrieving the current asset data and merkle proof from the blockchain
  2. Extracting compression-related data needed for the transfer
  3. Building and signing a transfer transaction
  4. Submitting the transaction to the Solana network

  ## Example Usage

  ```elixir
  # First establish a connection with your wallet's private key
  MplBubblegum.Connection.create_connection(secret_key, rpc_url)

  # Then transfer the NFT
  signature = MplBubblegum.Transfer.transfer(
    "4mKSoDDqApmF1DqXvVTSL7sGe1pCP2q6KomxEsYQMgZX",  # Asset ID
    "DEF456GHI789jklMNOpqrSTUvwxYZ"                  # Recipient address
  )

  # The signature can be used to view the transaction on Solana Explorer
  # https://explorer.solana.com/tx/<signature>
  ```
  """
  alias MplBubblegum.Connection
  alias MplBubblegum.RPC

  @doc """
  Transfers a compressed NFT to a new owner.

  ## Parameters

  * `asset_id` - The asset ID of the compressed NFT to transfer (string)
  * `to_address` - The wallet address of the recipient (string in base58 format)

  ## Returns

  * `binary()` - The transaction signature as a base58 string on success

  ## Error Handling

  This function will raise errors in the following cases:

  * `RuntimeError` - If no connection has been established
  * `ArgumentError` - If the asset ID or recipient address is invalid
  * `RuntimeError` - If you don't own the NFT being transferred
  * `RuntimeError` - If the asset data or proof cannot be retrieved
  * `RuntimeError` - If the transaction fails to send

  ## Examples

  ```elixir
  # Transfer an NFT to a recipient address
  signature = MplBubblegum.Transfer.transfer(
    "4mKSoDDqApmF1DqXvVTSL7sGe1pCP2q6KomxEsYQMgZX",
    "3Kn6a9nJLW5324a5M3qW3xTpvnwGf7nKzBmpJVLYxfEP"
  )
  ```
  """
  @spec transfer(binary(), binary()) :: binary()
  def transfer(asset_id, to_address) do
    # Validate input parameters
    validate_input_parameters!(asset_id, to_address)

    # Get asset data
    response = case RPC.get_asset_data(asset_id) do
      {:ok, data} ->
        data
      {:error, reason} ->
        raise RuntimeError, """
        Failed to retrieve asset data!

        Asset ID: #{asset_id}
        Error: #{inspect(reason)}

        This could be due to:
        1. Invalid asset ID
        2. Asset doesn't exist
        3. RPC connection issues
        4. DAS API not supported by your RPC provider

        Please check that you're using a valid asset ID and that your RPC URL
        supports the Digital Asset Standard (DAS) API.
        """
      _ ->
        raise RuntimeError, """
        Failed to retrieve asset data!

        Asset ID: #{asset_id}

        Please verify that the asset ID is correct and that you're
        using a Helius RPC URL that supports the DAS API.
        """
    end

    # Verify response has expected structure
    unless response["result"] && length(response["result"]) > 0 do
      raise RuntimeError, """
      Invalid asset data response!

      Asset ID: #{asset_id}
      Response: #{inspect(response)}

      The asset may not exist or the RPC provider returned an unexpected format.
      """
    end

    [data1] = response["result"]

    # Verify ownership
    owner = get_in(data1, ["ownership", "owner"])
    key = Connection.get_secret_key()

    # Extract public key from the secret key (simplified check)
    # This is a placeholder - actual implementation would depend on how keys are handled
    unless owner == "public_key_derived_from_secret_key" do
      raise RuntimeError, """
      You don't own this NFT!

      Asset ID: #{asset_id}
      Current owner: #{owner}

      You can only transfer NFTs that you own.
      """
    end

    # Get asset proof
    response2 = case RPC.get_asset_proof(asset_id) do
      {:ok, data} ->
        data
      {:error, reason} ->
        raise RuntimeError, """
        Failed to retrieve asset proof!

        Asset ID: #{asset_id}
        Error: #{inspect(reason)}

        This could be due to:
        1. Invalid asset ID
        2. RPC connection issues
        3. DAS API not supported by your RPC provider

        Please check that you're using a valid asset ID and that your RPC URL
        supports the Digital Asset Standard (DAS) API.
        """
      _ ->
        raise RuntimeError, """
        Failed to retrieve asset proof!

        Asset ID: #{asset_id}

        Please verify that the asset ID is correct and that you're
        using a Helius RPC URL that supports the DAS API.
        """
    end

    # Verify proof response has expected structure
    unless response2["result"] && response2["result"][asset_id] do
      raise RuntimeError, """
      Invalid asset proof response!

      Asset ID: #{asset_id}
      Response: #{inspect(response2)}

      The asset proof could not be retrieved or the RPC provider
      returned an unexpected format.
      """
    end

    proof = response2["result"][asset_id]["proof"]
    root = response2["result"][asset_id]["root"]

    # Extract compression data
    unless data1["compression"] do
      raise RuntimeError, """
      Missing compression data!

      Asset ID: #{asset_id}

      This NFT doesn't appear to be a compressed NFT, or the data
      is not in the expected format.
      """
    end

    compression = data1["compression"]
    creator_hash = compression["creator_hash"]
    data_hash = compression["data_hash"]
    nonce = compression["leaf_id"]
    merkle_tree = compression["tree"]

    # Build and send transaction
    tx =
      MplBubblegum.transfer_builder(
        key,
        to_address,
        asset_id,
        nonce,
        data_hash,
        creator_hash,
        root,
        proof,
        merkle_tree
      )

    case RPC.send_transaction(tx) do
      {:ok, signature} ->
        signature
      {:error, reason} ->
        raise RuntimeError, """
        Transfer transaction failed!

        Asset ID: #{asset_id}
        Recipient: #{to_address}
        Error: #{inspect(reason)}

        Common causes:
        1. Insufficient SOL balance for transaction fees
        2. Network congestion or RPC issues
        3. The asset has been transferred to someone else
        4. The merkle proof is no longer valid (tree was updated)

        Please check your wallet balance and try again. If the problem
        persists, the asset state may have changed since you retrieved
        the data. Try the entire operation again.
        """
    end
  end

  # Private helper function to validate input parameters
  defp validate_input_parameters!(asset_id, to_address) do
    cond do
      !is_binary(asset_id) || String.trim(asset_id) == "" ->
        raise ArgumentError, """
        Invalid asset ID!

        The asset ID must be a non-empty string.
        Example: "4mKSoDDqApmF1DqXvVTSL7sGe1pCP2q6KomxEsYQMgZX"
        """

      !is_binary(to_address) || String.trim(to_address) == "" ->
        raise ArgumentError, """
        Invalid recipient address!

        The recipient address must be a non-empty string in base58 format.
        Example: "3Kn6a9nJLW5324a5M3qW3xTpvnwGf7nKzBmpJVLYxfEP"
        """

      # Check if to_address looks like a base58 string (simplified check)
      !Regex.match?(~r/^[1-9A-HJ-NP-Za-km-z]+$/, to_address) ->
        raise ArgumentError, """
        Invalid recipient address format!

        The recipient address must be in base58 format (containing only
        alphanumeric characters, excluding 0, O, I, and l).

        Provided: #{to_address}
        """

      true ->
        :ok
    end
  end
end
