defmodule Sentry do
  import Sentry.Helpers, only: [verify_phoenix_deps!: 0]
  import Sentry.Authorizer

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
    authorize(conn, action, args)
  end

  def call(conn, [action: action]) do
    authorize(conn, action)
  end

  def call(conn, [args: args]) do
    authorize(conn, args)
  end

  def call(conn, _opts) do
    authorize(conn)
  end
end
