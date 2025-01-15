defmodule Smlr.Application do
  @moduledoc false

  use Application
  alias Smlr.Config
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    cache_opts = Config.config(:cache_opts, []) || %{}

    cachex =
      case Map.fetch(cache_opts, :limit) do
        {:ok, limit} when not is_nil(limit) ->
          Supervisor.child_spec({Cachex, [limit: limit, reclaim: 0.1]}, id: Smlr.DefaultCache)

        _ ->
          Supervisor.child_spec({Cachex, []}, id: Smlr.DefaultCache)
      end

    children = [
      cachex
    ]

    opts = [strategy: :one_for_one, name: Smlr.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
