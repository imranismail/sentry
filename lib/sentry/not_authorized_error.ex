defmodule Sentry.NotAuthorizedError do
  defexception message: "unauthorized action called, please check the resource policy"
end
