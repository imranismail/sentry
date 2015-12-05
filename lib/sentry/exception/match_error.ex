defmodule Sentry.Exception.MatchError do
  defexception plug_status: 500, message: "no matching clause", module: nil, function: nil, arity: nil

  def exception(opts) do
    module   = Keyword.fetch!(opts, :module) |> Module.split |> Enum.join(".")
    function = Keyword.fetch!(opts, :function)
    arity    = Keyword.fetch!(opts, :arity)

    %Sentry.Exception.MatchError{message: "no matching clause: expected a tuple of {:ok, any} or {:error, any} from #{module}.#{function}/#{arity}", module: module, function: function, arity: arity}
  end
end
