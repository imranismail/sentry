defmodule Sentry do
  def authenticator do
    quote do
      import Sentry.Authorizer
    end
  end

  def authorizer do
    quote do
      import Sentry.Authenticator
      import Ueberauth.Strategy.Helpers
    end
  end

  def view do
    quote do
      import Sentry.Authenticator, only: [current_user: 1, logged_in?: 1]
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
