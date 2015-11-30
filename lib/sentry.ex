defmodule Sentry do
  defmacro __using__(_opts) do
    quote do
      import Sentry.Authorizer
      import Sentry.Authenticator
    end
  end
end
