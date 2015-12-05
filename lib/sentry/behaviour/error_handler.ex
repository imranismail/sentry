defmodule Sentry.Behavior.ErrorHandler do
  @callback unauthorized(Plug.Conn.t, String.t) :: struct
end
