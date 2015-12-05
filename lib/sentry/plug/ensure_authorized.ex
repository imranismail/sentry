defmodule Sentry.Plug.EnsureAuthorized do
  import Sentry.Authorizer

  def init(opts) do
    Keyword.fetch!(opts, :handler)
  end

  def call(conn, handler) do
    case authorize(conn) do
      {:ok, conn} ->
        conn
      {:error, reason} ->
        apply(handler, :unauthorized, [conn, reason])
    end
  end
end
