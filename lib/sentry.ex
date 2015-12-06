defmodule Sentry do
  def authorizer do
    quote do
      import Sentry.Authorizer
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
