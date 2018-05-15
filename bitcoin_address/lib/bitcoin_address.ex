defmodule BitcoinAddress do
  @moduledoc false

  def write do
    private_key = keypair() |> elem(1)
    with file_path = ".keys/key",
      :ok <- File.write(file_path, private_key) do
        %{"dir": file_path, "key": private_key}
      else
        {:error, error} -> :file.format_error(error)
      end
  end

  defp keypair do
    {_, private_key} =
      with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
        do: {Base.encode16(public_key), Base.encode16(private_key)}
    {:ok, private_key}
  end
end
