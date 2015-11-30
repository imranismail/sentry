defmodule Sentry.Naming do
  @moduledoc """
  Helper functions for working with names
  """

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
end
