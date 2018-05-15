defmodule BitcoinAddress do
  @moduledoc false

  def keypair do
    with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
      do: {Base.encode16(public_key), Base.encode16(private_key)}
  end
end
