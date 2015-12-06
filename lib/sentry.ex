defmodule Sentry do
  def authorizer do
    quote do
      import Sentry.Authorizer

      def init(action) when is_atom(action) do
        action
      end

      def call(conn, action) do
        conn = update_in conn.private,
                 &(&1 |> Map.put(:sentry_module, __MODULE__)
                      |> Map.put(:sentry_function, action))

        if Map.has_key?(conn.private, :phoenix_router) do
          super(conn, action)
        end
      end
    end
  end

  def authenticator do
    quote do
      import Sentry.Authenticator
    end
  end

  def model do
    quote do
      import Sentry.Authenticator, only: [encrypt_password: 1]
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
