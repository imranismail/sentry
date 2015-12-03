defmodule Sentry.NotAuthorizedError do
  defexception plug_status: 401, message: "unauthorized action", reason: nil

  def exception(options) do
    reason = Keyword.fetch!(options, :reason)

    %Sentry.NotAuthorizedError{message: "unauthorized action: #{reason}", reason: reason}
  end
end
