defmodule BitcoinAddress do
  @moduledoc false

  @dir_keypair ".keys/key"

  def write do
    keys = keypair()
    public_key  = keys |> elem(0)
    private_key = keys |> elem(1)
    with file_path = @dir_keypair,
      :ok <- File.write(file_path, "#{[private_key, public_key] |> Enum.join(", ")}") do
        %{"dir": file_path, "pri": private_key, "pub": public_key}
      else
        {:error, error} -> :file.format_error(error)
      end
  end

  def sign do
    private_key = get_private_key()
    signature = :crypto.sign(
      :ecdsa,
      :sha256,
      "message",
      [private_key, :secp256k1]
    )
    {:ok, signature}
  end

  def verify do
    public_key = get_public_key()
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

  def address do
    # private_key
    # |> KeyPair.to_public_key()
    # |> hash_160()
    # |> prepend_version_byte(network)
    # |> Check.call()
    # |> Encode.call()
  end

  def to_public_key do
    {public_key, args} = :crypto.generate_key(:ecdh, :secp256k1, get_private_key())
    {public_key, args}
  end

  defp keypair do
    {public_key, private_key} =
      with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
        do: {Base.encode16(public_key), Base.encode16(private_key)}
    {public_key, private_key}
  end

  defp get_private_key do
    File.read(".keys/key")
    |> Tuple.to_list
    |> List.delete(:ok)
    |> List.to_string
    |> String.split(",")
    |> List.first
  end

  defp get_public_key do
    File.read(".keys/key")
    |> Tuple.to_list
    |> List.delete(:ok)
    |> List.to_string
    |> String.split(",")
    |> List.last
    |> String.trim
  end
end
