defmodule BitcoinAddress.Primary do
  @moduledoc false

  @dir_keypair ".keys/keys"
  @checksum_length 4
  @alphabet "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  @length String.length(@alphabet)
  @version_bytes %{
    main: <<0x00>>,
    test: <<0x6F>>
  }

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

  def read do
    private_key = get_private_key()
    public_key  = get_public_key()

    %{"dir": @dir_keypair, "pri": private_key, "pub": public_key}
  end

  def sign do
    private_key = get_private_key() |> Base.decode16 |> elem(1)

    signature = :crypto.sign(
      :ecdsa,
      :sha256,
      "message",
      [private_key, :secp256k1]
    )
    {:ok, signature}
  end

  def verify do
    public_key = get_public_key() |> Base.decode16 |> elem(1)
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

  def check do
    versioned_hash = prepend_version()

    versioned_hash
    |> sha256()
    |> sha256()
    |> checksum()
    |> append(versioned_hash)
  end

  def call(input, acc \\ "")
  def call(0, acc), do: acc

  def call(input, acc) when is_binary(input) do
    input
    |> :binary.decode_unsigned()
    |> call(acc)
    |> prepend_zeros(input)
  end

  def call(input, acc) do
    input
    |> div(@length)
    |> call(extended_hash(input, acc))
  end

  defp keypair do
    {public_key, private_key} =
      with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
        do: {Base.encode16(public_key), Base.encode16(private_key)}
    {public_key, private_key}
  end

  defp get_private_key do
    File.read(".keys/keys")
    |> Tuple.to_list
    |> List.delete(:ok)
    |> List.to_string
    |> String.split(",")
    |> List.first
  end

  defp get_public_key do
    File.read(".keys/keys")
    |> Tuple.to_list
    |> List.delete(:ok)
    |> List.to_string
    |> String.split(",")
    |> List.last
    |> String.trim
  end

  defp prepend_version do
    public_hash = to_public_hash()
    network = :main

    @version_bytes
    |> Map.get(network)
    |> Kernel.<>(public_hash)
  end

  defp to_public_key do
    {public_key, args} = :crypto.generate_key(
      :ecdh,
      :secp256k1,
      get_private_key()
    )

    {public_key, args}
  end

  defp to_public_hash do
    public_key = to_public_key() |> elem(0)

    public_key
    |> hash(:sha256)
    |> hash(:ripemd160)
  end

  defp extended_hash(input, acc) do
    @alphabet
    |> String.at(rem(input, @length))
    |> append(acc)
  end

  defp prepend_zeros(acc, input) do
    input
    |> encode_zeros()
    |> append(acc)
  end

  defp encode_zeros(input) do
    input
    |> leading_zeros()
    |> duplicate_zeros()
  end

  defp leading_zeros(input) do
    input
    |> :binary.bin_to_list()
    |> Enum.find_index(&(&1 != 0))
  end

  defp duplicate_zeros(count) do
    @alphabet
    |> String.first()
    |> String.duplicate(count)
  end

  defp hash(data, algorithm), do: :crypto.hash(algorithm, data)
  defp sha256(data), do: :crypto.hash(:sha256, data)
  defp checksum(<<checksum::bytes-size(@checksum_length), _::bits>>), do: checksum
  defp append(prefix, postfix), do: prefix <> postfix
end
