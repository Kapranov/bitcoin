defmodule LossTracker.PageProcessor do
  @moduledoc false

  import Plug.Conn

  alias LossTracker.BitcoinAPI

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> calculate_loss()
    |> build_page()
  end

  defp calculate_loss(conn) do
    current_price = BitcoinAPI.current_price()
    current_loss = BitcoinAPI.current_loss(current_price)

    conn
    |> assign(:current_price, current_price)
    |> assign(:current_loss, current_loss)
  end

  defp build_page(conn) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, render_page(conn))
  end

  defp render_page(conn) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <title>Bitcoin loss tracker</title>
        <style>
          html {
            background-color: #252839;
            color: #f2b632;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
            font-size: 24px;
            text-align: center;
          }
          div {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            padding: 3rem;
            border: 6px solid #f2b632;
            border-radius: 6px;
          }
          p {
          margin: 1rem 0;
          }
          p:first-of-type {
            font-size: 0.8rem;
            line-height: 1rem;
          }
          p:last-of-type {
            font-size: 1.4rem;
          }
          .percentage {
            font-weight: 700;
            font-size: 1.8rem;
          }
        </style>
      </head>
      <body>
        <div>
          <p>On May 15th 2018 Bitcoin price reached $#{BitcoinAPI.max_price()}</p>
          <p>Current Bitcoin value is $#{conn.assigns[:current_price]}</p>
          <p>You could have lost <span class="percentage">#{:erlang.float_to_binary(conn.assigns[:current_loss], [decimals: 1])}%</span> of your money!</p>
        </div>
      </body>
    </html>
    """
  end
end
