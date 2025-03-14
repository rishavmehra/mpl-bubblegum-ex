defmodule MplBubblegum.Connection do
  @moduledoc """
  Manages the connection to Solana RPC for Bubblegum NFT interactions.

  ## Connection Setup

  Before using any functionality in the MplBubblegum library, you must establish
  a connection to a Solana RPC endpoint using `create_connection/2`.

  ## Helius RPC Requirement

  **IMPORTANT:** You must use a Helius RPC URL (https://helius.xyz) as your RPC endpoint.
  Standard Solana RPC nodes do not support the Digital Asset Standard (DAS) API,
  which is required for compressed NFT operations.

  ## Example Usage

  ```elixir
  # Initialize the connection
  secret_key = "your_wallet_private_key"
  rpc_url = "https://your-helius-rpc-endpoint.helius.xyz/..."

  MplBubblegum.Connection.create_connection(secret_key, rpc_url)

  # Now you can use other MplBubblegum functions
  ```
  """
  use Agent

  @doc """
  Creates a new connection with the given secret key and RPC URL.

  ## Parameters

  * `secret_key` - The private key of your Solana wallet as a binary string
  * `rpc_url` - The Helius RPC endpoint URL as a binary string

  ## Returns

  * `{:ok, pid}` - If the connection was successfully created
  * `{:error, reason}` - If the connection could not be established

  ## Examples

  ```elixir
  MplBubblegum.Connection.create_connection(
    "your_wallet_private_key",
    "https://your-helius-rpc-endpoint.helius.xyz/..."
  )
  ```

  ## Error Handling

  Will raise an `ArgumentError` if the connection has already been established.
  If you need to change the connection details, restart your application.
  """
  def create_connection(secret_key, rpc_url) do
    case Agent.start_link(fn -> [secret_key, rpc_url] end, name: __MODULE__) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, _pid}} ->
        raise ArgumentError, """
        Connection already established!

        The MplBubblegum connection has already been initialized.
        You can only call create_connection/2 once per application lifecycle.

        If you need to change connection details:
        1. Restart your application
        2. Call create_connection/2 with new parameters
        """
      {:error, reason} ->
        {:error, "Failed to establish connection: #{inspect(reason)}"}
    end
  end

  @doc """
  Returns the stored secret key.

  ## Returns

  * `binary()` - The secret key provided during connection setup

  ## Error Handling

  Will raise a `RuntimeError` if called before establishing a connection
  with `create_connection/2`.

  ## Examples

  ```elixir
  secret_key = MplBubblegum.Connection.get_secret_key()
  ```
  """
  @spec get_secret_key() :: binary()
  def get_secret_key do
    try do
      Agent.get(__MODULE__, fn [key, _] -> key end)
    rescue
      ArgumentError ->
        raise RuntimeError, """
        Connection not established!

        You must call MplBubblegum.Connection.create_connection/2 before
        attempting to access the secret key.

        Example:
          MplBubblegum.Connection.create_connection(secret_key, rpc_url)
        """
    end
  end

  @doc """
  Returns the stored RPC URL.

  ## Returns

  * `binary()` - The RPC URL provided during connection setup

  ## Error Handling

  Will raise a `RuntimeError` if called before establishing a connection
  with `create_connection/2`.

  ## Examples

  ```elixir
  rpc_url = MplBubblegum.Connection.get_rpc_url()
  ```
  """
  @spec get_rpc_url() :: binary()
  def get_rpc_url do
    try do
      Agent.get(__MODULE__, fn [_, rpc_url] -> rpc_url end)
    rescue
      ArgumentError ->
        raise RuntimeError, """
        Connection not established!

        You must call MplBubblegum.Connection.create_connection/2 before
        attempting to access the RPC URL.

        Example:
          MplBubblegum.Connection.create_connection(secret_key, rpc_url)
        """
    end
  end
end
