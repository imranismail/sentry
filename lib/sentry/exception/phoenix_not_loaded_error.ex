defmodule Sentry.Exception.PhoenixNotLoadedError do
  defexception plug_status: 500, message: "this authorize function is only available to phoenix controllers. " <>
  "please use authorize(conn, policy, action_name: [arguments]) instead."
end
