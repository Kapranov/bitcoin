defmodule BitcoinAddress do
  @moduledoc false

  @directory_path ".keys"
  @file_name "key"
  @type_algorithm :ecdh
  @ecdsa_curve :secp256k1

  @n :binary.decode_unsigned(<<
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE,
    0xBA, 0xAE, 0xDC, 0xE6, 0xAF, 0x48, 0xA0, 0x3B,
    0xBF, 0xD2, 0x5E, 0x8C, 0xD0, 0x36, 0x41, 0x41
  >>)

  ###############################
  # CRUD DIRECTORY AND KEY FILE #
  ###############################

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

  ###############################
  # Generate Private Public Key #
  ###############################

  def to_public_key(private_key \\ get_private_key()) do
    private_key
    |> String.valid?()
    |> maybe_decode(private_key)
    |> generate_key()
  end

  ###############################

  defp keypair do
    with {public_key, private_key} <- generate(),
      do: {Base.encode16(public_key), Base.encode16(private_key)}
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
  defp generate, do: :crypto.generate_key(@type_algorithm, @ecdsa_curve)
  defp get_private_key, do: read() |> Map.get(:pri)
  defp maybe_decode(true,  private_key), do: Base.decode16!(private_key)
  defp maybe_decode(false, private_key), do: private_key
  defp maybe_create_directory(directory), do: File.mkdir_p(directory)
  defp translate(error), do: :file.format_error(error)
end
