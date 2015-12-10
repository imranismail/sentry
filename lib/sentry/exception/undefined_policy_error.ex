defmodule Sentry.Exception.UndefinedPolicyError do
  defexception plug_status: 500, message: "undefined policy.", policy: nil

  def exception(opts) do
    policy = Keyword.fetch!(opts, :policy) |> Module.split |> Enum.join(".")
    %Sentry.Exception.UndefinedPolicyError
    {
      message: "undefined policy: #{policy}.",
      policy: policy
    }
  end
end
