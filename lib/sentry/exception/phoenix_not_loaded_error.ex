defmodule Sentry.Exception.PhoenixNotLoadedError do
  defexception plug_status: 500, message: "you tried to use " <>
      "Sentry.Authorizer, but Phoenix module is not loaded. " <>
      "please add phoenix to your dependencies."
end
