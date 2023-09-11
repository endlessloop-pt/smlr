defmodule Smlr.Compressor.Brotli do
  @moduledoc false

  @behaviour Smlr.Compressor

  alias Smlr.Config

  def name do
    "br"
  end

  def default_level do
    4
  end

  def level(opts) do
    Config.get_compressor_level(__MODULE__, opts)
  end

  def compress(data, opts) do
    :brotli.encode(data, %{quality: level(opts)})
  end
end
