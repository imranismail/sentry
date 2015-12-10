defmodule Sentry do
  import Sentry.Helpers, only: [fetch_private!: 2]

  alias Sentry.Exception
  alias Sentry.Auth

  def init(opts) do
    unless Code.ensure_loaded?(Phoenix) do
      raise Exception.PhoenixNotLoadedError
    end
    opts
  end

  def call(conn, [handler: handler]) when is_atom(handler) do
    case Auth.authorize(conn) do
      {:ok, conn}      -> conn
      {:error, reason} ->
        conn
        |> fetch_private!(:phoenix_controller)
        |> apply(handler, [conn, reason])
    end
  end

  def call(conn, [handler: handler, args: args])
  when is_atom(handler) and is_list(args) do
    case Auth.authorize(conn, args) do
      {:ok, conn}      -> conn
      {:error, reason} ->
        conn
        |> fetch_private!(:phoenix_controller)
        |> apply(handler, [conn, reason])
    end
  end

  def call(conn, [policy: function, handler: handler])
  when is_atom(function) and is_atom(handler) do
    case Auth.authorize(conn, function) do
      {:ok, conn}      -> conn
      {:error, reason} ->
        conn
        |> fetch_private!(:phoenix_controller)
        |> apply(handler, [conn, reason])
    end
  end

  def call(conn, [policy: [module, function], handler: handler])
  when is_atom(module) and is_atom(function) and is_atom(handler) do
    call(conn, [policy: [module, function, []], handler: handler])
  end

  def call(conn, [policy: [module, function, args], handler: handler])
  when is_atom(module) and is_atom(function) and is_list(args) and is_atom(handler) do
    case apply(module, function, [conn] ++ args) do
      {:ok, conn}      -> conn
      {:error, reason} ->
        conn
        |> fetch_private!(:phoenix_controller)
        |> apply(handler, [conn, reason])
    end
  end

  defmacro __using__(_options) do
    quote do
      unless Code.ensure_loaded?(Phoenix) do
        raise Exception.PhoenixNotLoadedError
      end

      alias Sentry.Auth
      alias Sentry.Tokenizer
    end
  end
end
