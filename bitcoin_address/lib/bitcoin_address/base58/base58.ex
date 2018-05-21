defmodule BitcoinAddress.Base58 do
  @moduledoc false

  alias BitcoinAddress.Base58.{Check, Encode}

  def check_encode(input) do
    input
    |> Check.call()
    |> Encode.call()
  end
end
