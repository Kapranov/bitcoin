defmodule BitcoinAddress do
  @moduledoc false

  @dir_keypair ".keys/key"

  def write do
    private_key = keypair() |> elem(1)
    with file_path = @dir_keypair,
      :ok <- File.write(file_path, private_key) do
        %{"dir": file_path, "key": private_key}
      else
        {:error, error} -> :file.format_error(error)
      end
  end

  def sign do
    private_key = File.read(@dir_keypair) |> elem(1)
    signature = :crypto.sign(
      :ecdsa,
      :sha256,
      "message",
      [private_key, :secp256k1]
    )
    {:ok, signature}
  end

  defp keypair do
    {_, private_key} =
      with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
        do: {Base.encode16(public_key), Base.encode16(private_key)}
    {:ok, private_key}
  end
end
