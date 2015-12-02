defmodule Sentry.Helpers do
  @moduledoc """
  Helper functions for working with sentry and phoenix naming convention with some functions taken from Phoenix.Naming
  """

  alias Ueberauth.Auth
  alias Ueberauth.Auth.Extra

  @doc """
  The model module that is being used for authentication
  """
  def model, do: from_options(:model)

  @doc """
  The model name that is being used for authentiction
  """
  def model_name, do: model |> resource_name

  @doc """
  The uid_field atom from config.exs
  """
  def uid_key, do: from_options(:uid_field) || :email

  @doc """
  The password_field atom from config.exs
  """
  def password_key, do: from_options(:password_field) || :password

  @doc """
  The repo module that the user model is being checked against
  """
  def repo, do: from_options(:repo)

  @doc """
  The full list of options passed to the sentry in the configuration.
  """
  def options, do: from_options(:options)

  @doc """
  The full raw parameters from the Auth struct
  """
  def params(%{assigns: %{ueberauth_auth: auth}}) do
    %Auth{extra: %Extra{raw_info: params}} = auth
    params
  end

  @doc """
  The user params
  """
  def user_params(conn), do: Map.get(params(conn), model_name)

  @doc """
  The uid value in user_params
  """
  def uid(conn) do
    key = uid_key |> to_string
    %{^key => uid} = user_params(conn)
    uid
  end

  @doc """
  The password value in user params
  """
  def password(conn) do
    key = password_key |> to_string
    %{^key => password} = user_params(conn)
    password
  end

  @doc """
  Provides a convenient way to suffix string using pipes
      iex> "User" |> Sentry.Naming.suffix("Controller")
      "UserController"
  """
  def suffix(alias, suffix) do
    alias <> suffix
  end

  @doc """
  Extracts the resource name from an alias.
  ## Examples
      iex> Phoenix.Naming.resource_name(MyApp.User)
      "user"
      iex> Phoenix.Naming.resource_name(MyApp.UserView, "View")
      "user"
  """
  @spec resource_name(String.Chars.t, String.t) :: String.t
  def resource_name(alias, suffix \\ "") do
    alias
    |> to_string()
    |> Module.split()
    |> List.last()
    |> unsuffix(suffix)
    |> underscore()
  end

  @doc """
  Removes the given suffix from the name if it exists.
  ## Examples
      iex> Phoenix.Naming.unsuffix("MyApp.User", "View")
      "MyApp.User"
      iex> Phoenix.Naming.unsuffix("MyApp.UserView", "View")
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

  @doc """
  Converts String to underscore case.
  ## Examples
      iex> Phoenix.Naming.underscore("MyApp")
      "my_app"
  In general, `underscore` can be thought of as the reverse of
  `camelize`, however, in some cases formatting may be lost:
      Phoenix.Naming.underscore "SAPExample"  #=> "sap_example"
      Phoenix.Naming.camelize   "sap_example" #=> "SapExample"
  """
  @spec underscore(String.t) :: String.t

  def underscore(""), do: ""

  def underscore(<<h, t :: binary>>) do
    <<to_lower_char(h)>> <> do_underscore(t, h)
  end

  defp do_underscore(<<h, t, rest :: binary>>, _) when h in ?A..?Z and not (t in ?A..?Z or t == ?.) do
    <<?_, to_lower_char(h), t>> <> do_underscore(rest, t)
  end

  defp do_underscore(<<h, t :: binary>>, prev) when h in ?A..?Z and not prev in ?A..?Z do
    <<?_, to_lower_char(h)>> <> do_underscore(t, h)
  end

  defp do_underscore(<<?., t :: binary>>, _) do
    <<?/>> <> underscore(t)
  end

  defp do_underscore(<<h, t :: binary>>, _) do
    <<to_lower_char(h)>> <> do_underscore(t, h)
  end

  defp do_underscore(<<>>, _) do
    <<>>
  end

  defp to_lower_char(char) when char in ?A..?Z, do: char + 32
  defp to_lower_char(char), do: char

  @doc """
  Converts String to camel case.
  ## Examples
      iex> Phoenix.Naming.camelize("my_app")
      "MyApp"
  In general, `camelize` can be thought of as the reverse of
  `underscore`, however, in some cases formatting may be lost:
      Phoenix.Naming.underscore "SAPExample"  #=> "sap_example"
      Phoenix.Naming.camelize   "sap_example" #=> "SapExample"
  """
  @spec camelize(String.t) :: String.t
  def camelize(""), do: ""

  def camelize(<<?_, t :: binary>>) do
    camelize(t)
  end

  def camelize(<<h, t :: binary>>) do
    <<to_upper_char(h)>> <> do_camelize(t)
  end

  defp do_camelize(<<?_, ?_, t :: binary>>) do
    do_camelize(<< ?_, t :: binary >>)
  end

  defp do_camelize(<<?_, h, t :: binary>>) when h in ?a..?z do
    <<to_upper_char(h)>> <> do_camelize(t)
  end

  defp do_camelize(<<?_>>) do
    <<>>
  end

  defp do_camelize(<<?/, t :: binary>>) do
    <<?.>> <> camelize(t)
  end

  defp do_camelize(<<h, t :: binary>>) do
    <<h>> <> do_camelize(t)
  end

  defp do_camelize(<<>>) do
    <<>>
  end

  defp to_upper_char(char) when char in ?a..?z, do: char - 32
  defp to_upper_char(char), do: char

  @doc """
  Converts an attribute/form field into its humanize version.
      iex> Phoenix.Naming.humanize(:username)
      "Username"
      iex> Phoenix.Naming.humanize(:created_at)
      "Created at"
      iex> Phoenix.Naming.humanize("user_id")
      "User"
  """
  @spec humanize(atom | String.t) :: String.t
  def humanize(atom) when is_atom(atom),
    do: humanize(Atom.to_string(atom))
  def humanize(bin) when is_binary(bin) do
    bin =
      if String.ends_with?(bin, "_id") do
        binary_part(bin, 0, byte_size(bin) - 3)
      else
        bin
      end

    bin |> String.replace("_", " ") |> String.capitalize
  end

  defp from_options(key) do
    options = Application.get_env(:sentry, Sentry)
    if options, do: options[key], else: nil
  end
end
