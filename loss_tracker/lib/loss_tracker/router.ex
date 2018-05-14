defmodule LossTracker.Router do
  @moduledoc false

  use Plug.Router

  alias LossTracker.PageProcessor

  plug :match
  plug :dispatch

  get "/about" do
    send_resp(conn, 200, "This is a demo site")
  end

  match _ do
    PageProcessor.call(conn, PageProcessor.init([]))
  end
end
