defmodule BitcoinAddress do
  @moduledoc false

  @directory_path ".keys"
  @file_name "key"
  @type_algorithm :ecdh
  @ecdsa_curve :secp256k1

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

  def update(private_key \\ generate_key(), public_key \\ "",
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

  ##############################
  # Generate Private Public Key #
  ###############################

  #def to_public_key(private_key \\ get_private_key()) do
  #  private_key
  #  |> String.valid?()
  #  |> maybe_decode(private_key)
  #  |> generate_key()
  #end

  #def to_public_key(private_key \\ get_private()) do
  #  {public_key, _} = :crypto.generate_key(@type_algorithm, @ecdsa_curve, private_key)
  #  {public_key}
  #end

  #defp gen_private_key do
  #  :crypto.strong_rand_bytes(32) |> Base.encode16
  #end

  #defp set_private_key, do: :crypto.strong_rand_bytes(32) |> Base.encode16
  #defp set_public_key,  do: to_public_key() |> Base.encode16

  #defp get_private_key, do: read() |> Map.get(:pri)
  #defp get_public_key,  do: read() |> Map.get(:pub)
  #defp generate, do: :crypto.generate_key(@type_algorithm, @ecdsa_curve)
  #defp generate(private_key), do: :crypto.generate_key(@type_algorithm, @ecdsa_curve, private_key)
  #defp maybe_decode(true,  private_key), do: Base.decode16!(private_key)
  #defp maybe_decode(false, private_key), do: private_key

  #defp generate_key(private_key) do
  #  with {public_key, _private_key} <- generate(private_key), do: public_key
  #end
  ###############################

  defp keypair do
    with {public_key, private_key} <- generate(),
      do: {Base.encode16(public_key), Base.encode16(private_key)}
  end

  defp generate, do: :crypto.generate_key(@type_algorithm, @ecdsa_curve)
  defp generate_key, do: :crypto.strong_rand_bytes(32) |> Base.encode16
  defp maybe_create_directory(directory), do: File.mkdir_p(directory)
  defp translate(error), do: :file.format_error(error)
end
