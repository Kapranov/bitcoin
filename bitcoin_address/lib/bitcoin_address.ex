defmodule BitcoinAddress do
  @moduledoc false

  @directory_path ".keys"
  @file_name "key"
  @type_algorithm :ecdh
  @ecdsa_curve :secp256k1
  @version_bytes %{
    main: <<0x00>>,
    test: <<0x6F>>
  }

  @n :binary.decode_unsigned(<<
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE,
    0xBA, 0xAE, 0xDC, 0xE6, 0xAF, 0x48, 0xA0, 0x3B,
    0xBF, 0xD2, 0x5E, 0x8C, 0xD0, 0x36, 0x41, 0x41
  >>)

  ##################################
  # CRUD Create Directory Key file #
  ##################################

  def create(directory \\ @directory_path, file \\ @file_name) do
    keys = keypair()
    public_key  = keys |> elem(0)
    private_key = keys |> elem(1)

    with file_path = Path.join(directory, file),
        :ok <- maybe_create_directory(directory),
        :ok <- File.write(file_path, private_key),
        :ok <- File.write("#{file_path}.pub", public_key) do
      %{"dir": file_path, "pri": private_key, "pub": public_key}
    else
      {:error, error} -> translate(error)
    end
  end

  def read(directory \\ @directory_path, file \\ @file_name) do
    with file_path = Path.join(directory, file),
        {:ok, private_key} <- File.read(file_path),
        {:ok, public_key} <- File.read("#{file_path}.pub") do
      %{"pri": private_key, "pub": public_key}
    else
      {:error, error} -> translate(error)
    end
  end

  def update(private_key \\ encode_key(), public_key \\ "",
      directory \\ @directory_path, file \\ @file_name) do
    with file_path = Path.join(directory, file),
        :ok <- File.write(file_path, private_key),
        :ok <- File.write("#{file_path}.pub", public_key) do
      %{"dir": file_path, "pri": private_key, "pub": public_key}
    else
      {:error, error} -> translate(error)
    end
  end

  def destroy(directory \\ @directory_path) do
    with {:ok, files} <- File.rm_rf(directory) do
      %{"deleted": files}
    else
      {:error, reason, _file} -> translate(reason)
    end
  end

  ##################################
  #   Generate Private  PublicKey  #
  ##################################

  def to_public_key(private_key \\ get_private_key()) do
    private_key
    |> String.valid?()
    |> maybe_decode(private_key)
    |> generate_key()
  end

  ##################################
  #   Generate Compress PublicKey  #
  ##################################

  def to_compressed_public_key(private_key \\ get_private_key()) do
    {<<0x04, x::binary-size(32), y::binary-size(32)>>, _} =
      :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), private_key)

    if rem(:binary.decode_unsigned(y), 2) == 0 do
      <<0x02>> <> x
    else
      <<0x03>> <> x
    end
  end

  ##################################
  #   Generate  PublicKey to Hash  #
  ##################################

  def to_public_hash(private_key \\ get_private_key()) do
    private_key
    |> to_public_key()
    |> hash(:sha256)
    |> hash(:ripemd160)
  end

  ##################################
  #     Generate Bitcoin Address   #
  ##################################

  def to_public_address(private_key \\ get_private_key(), version \\ :main) do
    private_key
    |> to_public_hash()
    |> prepend_version_byte(version)
  end

  ##################################

  defp keypair do
    with {public_key, private_key} <- generate(),
      do: {Base.encode16(public_key), Base.encode16(private_key)}
  end

  defp generate do
    {public_key, private_key} = :crypto.generate_key(@type_algorithm, @ecdsa_curve)

    case valid?(private_key) do
      true  -> private_key
      false -> generate()
    end

    {public_key, private_key}
  end

  defp generate_key(private_key) do
    with {public_key, _private_key} <-
        :crypto.generate_key(@type_algorithm, @ecdsa_curve, private_key),
      do: public_key
  end

  defp generate_private_key do
    private_key = :crypto.strong_rand_bytes(32)

    case valid?(private_key) do
      true  -> private_key
      false -> generate_private_key()
    end
  end

  defp valid?(key) when is_binary(key) do
    key
    |> :binary.decode_unsigned()
    |> valid?
  end

  defp valid?(key) when key > 1 and key < @n, do: true
  defp valid?(_), do: false
  defp encode_key, do: generate_private_key() |> Base.encode16
  defp get_private_key, do: read() |> Map.get(:pri)
  defp maybe_decode(true,  private_key), do: Base.decode16!(private_key)
  defp maybe_decode(false, private_key), do: private_key
  defp maybe_create_directory(directory), do: File.mkdir_p(directory)
  defp translate(error), do: :file.format_error(error)
  defp hash(data, algorithm), do: :crypto.hash(algorithm, data)

  defp prepend_version_byte(public_hash, version) do
    @version_bytes
    |> Map.get(version)
    |> Kernel.<>(public_hash)
  end
end

defmodule Base58 do
  @alphabet '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

  def encode(data, hash \\ "")

  def encode(data, hash) when is_binary(data) do
    encode(:binary.decode_unsigned(data), hash)
  end

  def encode(0, hash), do: hash

  def encode(data, hash) do
    character = <<Enum.at(@alphabet, rem(data, 58))>>
    encode(div(data, 58), hash <> character)
  end
end
