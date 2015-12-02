defmodule Sentry.MatchError do
  defexception plug_status: 500, message: "no matching clause", module: nil, function: nil, arity: nil

  def exception(options) do
    module   = Keyword.fetch!(options, :module) |> Module.split |> Enum.join(".")
    function = Keyword.fetch!(options, :function)
    arity    = Keyword.fetch!(options, :arity)

    %Sentry.MatchError{message: "no matching clause: expected a tuple of {:ok, result} or {:error, reason} from #{module}.#{function}/#{arity}", module: module, function: function, arity: arity}
  end
end
