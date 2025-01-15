defmodule Smlr.Application do
  @moduledoc false

  use Application
  alias Smlr.Config
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    cache_opts = Config.config(:cache_opts, []) || %{}

    cachex =
      case Map.fetch(cache_opts, :limit) do
        {:ok, nil} ->
          {Cachex, [Smlr.DefaultCache, []]}

        {:ok, limit} ->
          {Cachex, [Smlr.DefaultCache, [limit: limit, reclaim: 0.1]]}

        _ ->
          {Cachex, [Smlr.DefaultCache, []]}
      end

    children = [
      cachex
    ]

    opts = [strategy: :one_for_one, name: Smlr.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
