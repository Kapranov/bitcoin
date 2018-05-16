defmodule BitcoinAddress do
  @moduledoc false

  @dir_keypair ".keys/key"

  def write do
    keys = keypair()
    public_key  = keys |> elem(0)
    private_key = keys |> elem(1)
    with file_path = @dir_keypair,
      :ok <- File.write(file_path, "#{[public_key, private_key] |> Enum.join(",")}") do
        %{"dir": file_path, "pri": private_key, "pub": public_key}
      else
        {:error, error} -> :file.format_error(error)
      end
  end

  def sign do
    private_key = File.read(".keys/key")
                  |> Tuple.to_list
                  |> List.delete(:ok)
                  |> List.to_string
                  |> String.split(",")
                  |> List.first

    signature = :crypto.sign(
      :ecdsa,
      :sha256,
      "message",
      [private_key, :secp256k1]
    )
    {:ok, signature}
  end

  def verify do
    public_key = File.read(".keys/key")
                 |> Tuple.to_list
                 |> List.delete(:ok)
                 |> List.to_string
                 |> String.split(",")
                 |> List.last

    signature = sign() |> elem(1)

    varify = :crypto.verify(
    :ecdsa,
    :sha256,
    "message",
    signature,
    [public_key, :secp256k1]
    )
    {:ok, varify}
  end

  defp keypair do
    {public_key, private_key} =
      with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
        do: {Base.encode16(public_key), Base.encode16(private_key)}
    {public_key, private_key}
  end
end
