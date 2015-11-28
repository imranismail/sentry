defmodule Sentry do
  defmacro __using__(_opts) do
    quote do
      import Sentry.Authorizer
    end
  end
end
