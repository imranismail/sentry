defmodule Sentry.UndefinedPolicyError do
  defexception plug_status: 500, message: "undefined policy", policy: nil

  def exception(options) do
    policy = Keyword.fetch!(options, :policy) |> Module.split |> Enum.join(".")
    %Sentry.UndefinedPolicyError{message: "undefined policy: #{policy}", policy: policy}
  end
end
