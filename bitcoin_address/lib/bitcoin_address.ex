defmodule BitcoinAddress do
  @moduledoc false

  @directory_path ".keys"
  @file_name "key"

  ###############################
  # CRUD DIRECTORY AND KEY FILE #
  ###############################

  def create(private_key \\ get_private_key(), public_key \\ get_public_key(),
      directory \\ @directory_path, file \\ @file_name) do
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

  @type_algorithm :ecdh
  @ecdsa_curve :secp256k1

  def to_public_key(private_key \\ get_private()) do
    private_key
    |> String.valid?()
    |> maybe_decode(private_key)
    |> generate_key()
  end

  defp get_private, do: read() |> Map.get(:pri)
  defp generate(private_key), do: :crypto.generate_key(@type_algorithm, @ecdsa_curve, private_key)
  defp maybe_decode(true, private_key), do: Base.decode16!(private_key)
  defp maybe_decode(false, private_key), do: private_key

  defp generate_key(private_key) do
    with {public_key, _private_key} <- generate(private_key), do: public_key
  end
  ###############################

  defp keypair do
    {public_key, private_key} =
      with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
        do: {Base.encode16(public_key), Base.encode16(private_key)}
    {public_key, private_key}
  end

  defp get_public_key,  do: keypair() |> elem(0)
  defp get_private_key, do: keypair() |> elem(1)
  defp maybe_create_directory(directory), do: File.mkdir_p(directory)
  defp translate(error), do: :file.format_error(error)
end
