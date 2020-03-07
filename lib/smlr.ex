defmodule Smlr do
  @behaviour Plug
  @moduledoc ~S"""
  Compresses the output of the plug with the correct compressor,
  if enabled cache the compressed output so that when requested again we can return it instantly
  rather than having to compress it again.

  Add the plug at the bottom of one or more pipelines in `router.ex`:

      pipeline "myapp" do
        # ...
        plug (Smlr)
      end
  """
  require Logger
  alias Smlr.{Cache, Config}
  alias Plug.Conn

  @impl Plug
  @doc ~S"""
  Init function sets all default variables and .
  """
  def init(opts) when is_list(opts) do
    opts
    |> Enum.chunk_every(2)
    |> Enum.into(%{}, fn [key, val] -> {key, val} end)
    |> init()
  end

  def init(opts) do
    opts
  end

  defp parse_request_header([], _compressors, _ignore_client_weight) do
    nil
  end

  defp parse_request_header([header], compressors, true) do
    schemes =
      String.downcase(header)
      |> String.split(",")
      |> Enum.map(fn scheme ->
        scheme
        |> String.split(";")
        |> Enum.at(0)
        |> String.trim()
      end)

    Enum.find(compressors, nil, fn compressor ->
      compressor.name() in schemes
    end)
  end

  defp parse_request_header([header], compressors, false) do
    schemes = String.split(header, ",")

    {choice, _weight} =
      Enum.reduce(schemes, {nil, -1}, fn scheme, acc ->
        split_scheme = String.split(scheme, ";")

        case Enum.count(split_scheme) do
          1 ->
            Enum.at(split_scheme, 0)
            |> String.trim()
            |> String.downcase()
            |> enabled_compressor(compressors)
            |> choose_compressor(acc)

          2 ->
            new_weight = get_weight(Enum.at(split_scheme, 1))

            Enum.at(split_scheme, 0)
            |> String.trim()
            |> String.downcase()
            |> enabled_compressor(compressors, new_weight)
            |> choose_compressor(acc)
        end
      end)

    choice
  end

  defp get_weight(weight) do
    split_string = String.split(weight, "=")

    case Enum.count(split_string) do
      2 ->
        number =
          Enum.at(split_string, 1)
          |> String.trim()

        case String.contains?(number, ".") do
          true ->
            Float.parse(number)

          false ->
            Integer.parse(number)
        end

      _ ->
        -1
    end
  end

  defp choose_compressor({new_choice, new_choice_weight}, {current_choice, current_choice_weight}) do
    case current_choice_weight >= new_choice_weight do
      true ->
        {current_choice, current_choice_weight}

      false ->
        {new_choice, new_choice_weight}
    end
  end

  defp enabled_compressor(compression, compressors, weight \\ 0) do
    case Enum.find(compressors, nil, fn compressor ->
           compressor.name() == compression
         end) do
      nil ->
        {nil, -1}

      compressor ->
        {compressor, weight}
    end
  end

  @impl Plug
  @doc ~S"""
  Call function. we check to see if the client has requested compression if it has, we register call back and compress before sending
  """
  @spec call(Conn.t(), Keyword.t()) :: Conn.t()
  def call(conn, opts) do
    case Config.config(:enabled, opts) do
      true ->
        conn
        |> Conn.get_req_header("accept-encoding")
        |> parse_request_header(Config.config(:compressors, opts), Config.config(:ignore_client_weight, opts))
        |> pass_or_compress(conn, opts)

      false ->
        conn
    end
  end

  defp pass_or_compress(nil, conn, _opts) do
    :telemetry.execute([:smlr, :request, :pass], %{}, %{path: conn.request_path})
    conn
  end

  defp pass_or_compress(compressor, conn, opts) do
    Conn.register_before_send(conn, fn conn ->
      compress_response(conn, Map.put(opts, :compressor, compressor))
    end)
  end

  defp compress_response(conn, opts) do
    conn
    |> Conn.put_resp_header("content-encoding", opts.compressor.name())
    |> Map.put(:resp_body, compress(conn.resp_body, conn.request_path, opts))
  end

  defp compress(body, path, opts) do
    # We do this because io lists are a pain and strings are easy
    case Cache.get_from_cache(body, opts.compressor.name(), Config.config(:cache_opts, opts)) do
      nil ->
        :telemetry.execute([:smlr, :request, :compress], %{}, %{
          path: path,
          compressor: opts.compressor.name(),
          level: opts.compressor.level(opts)
        })

        opts.compressor.compress(:erlang.iolist_to_binary(body), opts)
        |> Cache.set_for_cache(body, opts.compressor.name(), Config.config(:cache, opts))

      compressed ->
        :telemetry.execute([:smlr, :request, :cache], %{}, %{
          path: path,
          compressor: opts.compressor.name(),
          level: opts.compressor.level(opts)
        })

        compressed
    end
  end
end
