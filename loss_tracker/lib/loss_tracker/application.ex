defmodule LossTracker.Application do
  @moduledoc false

  alias LossTracker.Router

  use Application

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(
        scheme: :http,
        plug: Router,
        options: [port: 4001]
      )
    ]

    opts = [strategy: :one_for_one, name: LossTracker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
