defmodule Sentry.Exception.PrivateKeyNotLoadedError do
  defexception plug_status: 500, message: "you tried to use " <>
    "Sentry but it requires the phoenix controller pipeline " <>
    "to assign the private `:phoenix_controller` and `:phoenix_action` " <>
    "keys and values to the connection", key: nil


  def exception(opts) do
    key = Keyword.fetch!(opts, :key)
    %Sentry.Exception.PrivateKeyNotLoadedError
    {
      message: "you tried to " <>
        "use Sentry.Authorizer module but it requires phoenix controller " <>
        "pipeline to assign the `#{key}` key and value to the connection.",
      key: key
    }
  end
end
