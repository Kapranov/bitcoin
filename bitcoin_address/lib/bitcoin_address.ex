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

  #################################################################
  # Create Directory, CRUD are Keys files for Public, Private Key #
  # A Bitcoin private key is really just  a random  two  hundred  #
  # fifty  six  bit  number. As  the name implies, this number is #
  # intended  to  be  kept  private.  From  each  private  key,   #
  # a public-facing Bitcoin address can be generated. Bitcoin can #
  # be sent to this public address by anyone in the world.However #
  # only the  keeper  of  the private key can produce a signature #
  # that allows them to access the Bitcoin stored there.          #
  #################################################################

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

  #################################################################
  # Generate Public Key by Private Key.                           #
  # Bitcoin private key is really just  a random two  hundred and #
  # fifty six  bit  number. In other words, a private key  can be #
  # any number between 0 and 2^256.                               #
  # The most basic process for turning a Bitcoin private key into #
  # a sharable public address involves three basic steps.         #
  # The first step  is to transform our private key into a public #
  # key with the help of elliptic curve cryptography.             #
  #################################################################

  def to_public_key(private_key \\ get_private_key()) do
    private_key
    |> String.valid?()
    |> maybe_decode(private_key)
    |> generate_key()
  end

  #################################################################
  # Generate Compress Public Key                                  #
  #################################################################

  def to_compressed_public_key(private_key \\ get_private_key()) do
    {<<0x04, x::binary-size(32), y::binary-size(32)>>, _} =
      :crypto.generate_key(:ecdh, :crypto.ec_curve(:secp256k1), private_key)

    if rem(:binary.decode_unsigned(y), 2) == 0 do
      <<0x02>> <> x
    else
      <<0x03>> <> x
    end
  end

  #################################################################
  # Generate Public Key to Public Hash. We have our public key in #
  # memory our next step in transforming it into a public address #
  # is to hash it.                                                #
  #################################################################

  def to_public_hash(private_key \\ get_private_key()) do
    private_key
    |> to_public_key()
    |> hash(:sha256)
    |> hash(:ripemd160)
  end

  #################################################################
  # Generate Bitcoin Address - Public Hash to Public Address.     #
  # We  can  convert our  public hash into a full-fledged Bitcoin #
  # address  by Base58Check encoding the hash with a version byte #
  # corresponding to the network where we're using the address.   #
  #################################################################

  def to_public_address(private_key \\ get_private_key(), version \\ @version_bytes.main) do
    private_key
    |> to_public_hash()
    |> Base58Check.encode(version)
  end

  #################################################################

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
end

defmodule Base58 do
  @alphabet '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'

  #################################################################
  # Base58 is a binary-to-text encoding algorithm that's designed #
  # to encode a blob of arbitrary binary data into human readable #
  # text, much like the more well known Base64 algorithm.         #
  #################################################################

  def encode(data, hash \\ "")

  def encode(data, hash) when is_binary(data) do
    encode_zeros(data) <> encode(:binary.decode_unsigned(data), hash)
  end

  def encode(0, hash), do: hash

  def encode(data, hash) do
    character = <<Enum.at(@alphabet, rem(data, 58))>>
    encode(div(data, 58), character <> hash)
  end

  defp encode_zeros(data) do
    <<Enum.at(@alphabet, 0)>>
    |> String.duplicate(leading_zeros(data))
  end

  defp leading_zeros(data) do
    :binary.bin_to_list(data)
    |> Enum.find_index(&(&1 != 0))
  end
end

defmodule Base58Check do

  #################################################################
  # Base58Check  encoding  is  really  just  Base58 with an added #
  # checksum. This checksum is important to in  the Bitcoin world #
  # to ensure that public addresses aren't mistyped  or corrupted #
  # before funds are exchanged.                                   #
  #                                                               #
  # At a high level, the process of Base58Check  encoding  a blob #
  # of  binary  data involves hashing that data, taking the first #
  # four  bytes of  the  resulting hash and appending them to the #
  # end of the binary, and Base58 encoding the result.            #
  #################################################################

  def encode(data, version) do
    (version <> data <> checksum(data, version))
    |> Base58.encode()
  end

  defp checksum(data, version) do
    (version <> data)
    |> sha256
    |> sha256
    |> split
  end

  defp split(<<hash::bytes-size(4), _::bits>>), do: hash
  defp sha256(data), do: :crypto.hash(:sha256, data)
end
