defmodule Sentry do
  alias Plug.Conn

  defmacro __using__(_opts) do
    quote do
      import Sentry.Authorizer
      import Sentry.Authenticator
    end
  end

  def init(options \\ []) do
    options = Keyword.merge(Application.get_env(:sentry, Sentry), options)
  end

  def call(conn, options) do
    Conn.put_private(conn, :sentry_options, options)
  end
end
