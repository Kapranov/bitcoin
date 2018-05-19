defmodule BitcoinAddress.Address do
  @moduledoc false

  alias BitcoinAddress.Keys.Pair
  alias BitcoinAddress.Base58

  @dir_keypair ".keys/key"
  @version_bytes %{
    main: <<0x00>>,
    test: <<0x6F>>
  }

  def create do
    keys = Pair.create
    public_key  = keys |> elem(0)
    private_key = keys |> elem(1)
    with file_path = @dir_keypair,
      :ok <- File.write(file_path, "#{[private_key, public_key] |> Enum.join(", ")}") do
        %{"dir": file_path, "pri": private_key, "pub": public_key}
      else
        {:error, error} -> :file.format_error(error)
      end
  end

  def calculate(network \\ :main) do
    private_key = get_private_key()

    private_key
    |> Pair.to_public_key
    |> hash_160()
    |> prepend_version_byte(network)
    |> Base58.check_encode()
  end

  defp get_private_key do
    File.read(".keys/key")
    |> Tuple.to_list
    |> List.delete(:ok)
    |> List.to_string
    |> String.split(",")
    |> List.first
  end

  #defp keypair do
  #  {public_key, private_key} =
  #    with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
  #      do: {Base.encode16(public_key), Base.encode16(private_key)}
  #  {public_key, private_key}
  #end

  defp hash_160(public_key) do
    public_key
    |> hash(:sha256)
    |> hash(:ripemd160)
  end

  defp hash(data, algorithm), do: :crypto.hash(algorithm, data)

  defp prepend_version_byte(public_hash, network) do
    @version_bytes
    |> Map.get(network)
    |> Kernel.<>(public_hash)
  end
end
