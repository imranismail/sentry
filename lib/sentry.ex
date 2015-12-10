defmodule Sentry do
  import Sentry.Helpers, only: [fetch_private!: 2, verify_phoenix_deps!: 0]
  alias Sentry.Auth

  def init(opts) do
    verify_phoenix_deps!
    opts
  end

  def call(conn, [policy: policy, action: action, args: args]) do
    apply(policy, action, [conn] ++ args)
  end

  def call(conn, [policy: policy, action: action]) do
    apply(policy, action, [conn])
  end

  def call(conn, [action: action, args: args]) do
    Auth.authorize(conn, action, args)
  end

  def call(conn, [action: action]) do
    Auth.authorize(conn, action)
  end

  def call(conn, [args: args]) do
    Auth.authorize(conn, args)
  end

  def call(conn, _opts) do
    Auth.authorize(conn)
  end

  defmacro __using__(_options) do
    quote do
      unquote(verify_phoenix_deps!)
      alias Sentry.Auth
      alias Sentry.Tokenizer
    end
  end
end
