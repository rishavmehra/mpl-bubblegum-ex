defmodule MplBubblegum.RPC do
  @moduledoc """
  Handles RPC communication with the Solana blockchain for compressed NFT operations.

  ## Overview

  This module provides functions to interact with the Solana blockchain through
  RPC API calls, specifically for compressed NFT (cNFT) operations using the
  Digital Asset Standard (DAS) API.

  ## Requirements

  * A connection must be established with `MplBubblegum.Connection.create_connection/2`
  * A Helius RPC URL is required as the standard Solana RPC endpoints don't support DAS API

  ## API Methods

  The module supports the following Solana RPC methods:

  * `sendTransaction` - Submit a signed transaction to the Solana network
  * `getAssetBatch` - Retrieve metadata for compressed NFTs (DAS API)
  * `getAssetProofBatch` - Retrieve merkle proofs for compressed NFTs (DAS API)
  """
  alias MplBubblegum.Connection

  @doc """
  Sends a signed transaction to the Solana network.

  ## Parameters

  * `tx_hash` - The base64-encoded transaction as a string

  ## Returns

  * `{:ok, signature}` - On successful transaction submission, returns the transaction signature
  * `{:error, reason}` - On failure, returns the error reason

  ## Error Handling

  Common error cases include:

  * Connection not established
  * Invalid RPC URL
  * Network connectivity issues
  * Invalid transaction format
  * Transaction simulation failure (e.g., insufficient funds)

  ## Examples

  ```elixir
  case MplBubblegum.RPC.send_transaction(signed_transaction) do
    {:ok, signature} ->
      # Transaction submitted successfully
      # The signature can be used to check the transaction on Solana Explorer

    {:error, reason} ->
      # Handle error case
  end
  ```
  """
  @spec send_transaction(String.t()) :: {:ok, String.t()} | {:error, any()}
  def send_transaction(tx_hash) do
    rpc_url = Connection.get_rpc_url()

    request_body =
      %{
        jsonrpc: "2.0",
        id: 1,
        method: "sendTransaction",
        params: [tx_hash, %{encoding: "base64"}]
      }
      |> Jason.encode!()

    headers = [{"Content-Type", "application/json"}]

    case(HTTPoison.post(rpc_url, request_body, headers)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"result" => result}} -> {:ok, result}
          {:ok, %{"error" => error}} -> {:error, error}
          {:error, _} -> {:error, "Invalid JSON response"}
        end

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, %{status: status, message: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{status: "network_error", message: reason}}
    end
  end

  @doc """
  Gets asset data for a compressed NFT using the Digital Asset Standard (DAS) API.

  ## Parameters

  * `asset_id` - The asset ID of the compressed NFT

  ## Returns

  * `{:ok, asset_data}` - The asset data as a map on success
  * `{:error, reason}` - Error information on failure

  ## Examples

  ```elixir
  case MplBubblegum.RPC.get_asset_data("4mKSoDDqApmF1DqXvVTSL7sGe1pCP2q6KomxEsYQMgZX") do
    {:ok, asset_data} ->
      # Process the asset data

    {:error, reason} ->
      # Handle the error
  end
  ```
  """
  @spec get_asset_data(String.t()) :: {:ok, map()} | {:error, map()}
  def get_asset_data(asset_id) do
    rpc_url = Connection.get_rpc_url()

    request_body =
      %{
        "id" => "test",
        "jsonrpc" => "2.0",
        "method" => "getAssetBatch",
        "params" => %{
          "ids" => [asset_id]
        }
      }
      |> Jason.encode!()

    headers = [{"Content-Type", "application/json"}]

    case(HTTPoison.post(rpc_url, request_body, headers)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, %{status: status, message: "HTTP error", details: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{status: "network_error", message: "Request failed", details: reason}}
    end
  end

  @doc """
  Gets asset proof for a compressed NFT using the Digital Asset Standard (DAS) API.

  The proof is used to verify the authenticity and ownership of compressed NFTs
  stored in a merkle tree.

  ## Parameters

  * `asset_id` - The asset ID of the compressed NFT

  ## Returns

  * `{:ok, proof_data}` - The asset proof as a map on success
  * `{:error, reason}` - Error information on failure

  ## Examples

  ```elixir
  case MplBubblegum.RPC.get_asset_proof("4mKSoDDqApmF1DqXvVTSL7sGe1pCP2q6KomxEsYQMgZX") do
    {:ok, proof_data} ->
      # Process the proof data

    {:error, reason} ->
      # Handle the error
  end
  ```
  """
  @spec get_asset_proof(String.t()) :: {:ok, map()} | {:error, map()}
  def get_asset_proof(asset_id) do
    rpc_url = Connection.get_rpc_url()

    asset_proof_request =
      %{
        "id" => "test",
        "jsonrpc" => "2.0",
        "method" => "getAssetProofBatch",
        "params" => %{
          "ids" => [asset_id]
        }
      }
      |> Jason.encode!()

    headers = [{"Content-Type", "application/json"}]

    case(HTTPoison.post(rpc_url, asset_proof_request, headers)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
        {:error, %{status: status, message: "HTTP error", details: body}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{status: "network_error", message: "Request failed", details: reason}}
    end
  end
end
