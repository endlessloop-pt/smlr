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
          {Cachex, {Cachex, :start_link, [Smlr.DefaultCache, [limit: limit, reclaim: 0.1]]}, :permanent, 5000, :worker, [Cachex]}

        _ ->
          {Cachex, {Cachex, :start_link, [Smlr.DefaultCache, []]}, :permanent, 5000, :worker, [Cachex]}
      end

    children = [
      cachex
    ]

    opts = [strategy: :one_for_one, name: Smlr.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
