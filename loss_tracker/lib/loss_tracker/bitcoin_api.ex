defmodule LossTracker.BitcoinAPI do
  @moduledoc false

  @max_price 17_032.78
  @api_url "https://www.bitstamp.net/api/ticker/"

  def current_loss(current_price) do
    (@max_price - current_price) / @max_price * 100
  end

  def current_price do
    case HTTPoison.get(@api_url) do
      {:ok, response} ->
        response.body
        |> Poison.decode!
        |> Map.get("last")
        |> String.to_float
      {:error, _} ->
        nil
    end
  end

  def max_price do
    @max_price
  end
end
