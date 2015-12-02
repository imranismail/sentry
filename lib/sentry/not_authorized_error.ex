defmodule Sentry.NotAuthorizedError do
  defexception message: "unauthorized action called, please check the policy action"
end
