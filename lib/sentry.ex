defmodule Sentry do
  defmacro __using__(_opts) do
    quote do
      import Sentry.Authorizer, only: [authorize: 2, authorize: 3]
    end
  end
end
