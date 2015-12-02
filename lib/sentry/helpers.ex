defmodule Sentry.Helpers do
  @moduledoc """
  Helper functions for working with sentry
  """

  @doc """
  The model module that is being used for authentication
  """
  def model(conn), do: from_private(conn, :model)

  @doc """
  The repo module that the user model is being checked against
  """
  def repo(conn), do: from_private(conn, :repo)

  @doc """
  The full list of options passed to the sentry in the configuration.
  """
  @spec options(Plug.t) :: Keyword.t
  def options(conn), do: from_private(conn, :options)

  @doc """
  Provides a convenient way to suffix string using pipes
      iex> "User" |> Sentry.Naming.suffix("Controller")
      "UserController"
  """
  def suffix(alias, suffix) do
    alias <> suffix
  end

  @doc """
  Taken from Phoenix.Naming
  Removes the given suffix from the name if it exists.
  ## Examples
      iex> Sentry.Naming.unsuffix("MyApp.User", "View")
      "MyApp.User"
      iex> Sentry.Naming.unsuffix("MyApp.UserView", "View")
      "MyApp.User"
  """
  @spec unsuffix(String.t, String.t) :: String.t
  def unsuffix(value, suffix) do
    string = to_string(value)
    suffix_size = byte_size(suffix)
    prefix_size = byte_size(string) - suffix_size
    case string do
      <<prefix::binary-size(prefix_size), ^suffix::binary>> -> prefix
      _ -> string
    end
  end

  defp from_private(conn, key) do
    options = conn.private[:sentry_options]
    if options, do: options[key], else: nil
  end
end
