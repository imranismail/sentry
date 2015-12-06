defmodule Sentry.Helpers do
  alias Ecto.Changeset
  alias Sentry.Helpers
  alias Sentry.Options

  def uid_from(%Ecto.Changeset{} = changeset), do: Changeset.get_change(changeset, Options.uid_field)

  def password_from(%Ecto.Changeset{} = changeset), do: Changeset.get_change(changeset, Options.password_field)

  def apply_policy(module, function, args) do
    Helpers.verify_policy!(module)

    case apply(module, function, args) do
      {:ok, result}    -> {:ok, result}
      {:error, reason} -> {:error, reason}
      _                -> raise Exception.MatchError, module: module,
                                                      function: function,
                                                      arity: length(args)
    end
  end

  def verify_policy!(policy) do
    unless Code.ensure_loaded?(policy) do
      raise Exception.UndefinedPolicyError, policy: policy
    end
  end

  def verify_phoenix_controller!(conn) do
    unless Code.ensure_loaded?(Phoenix) && Map.has_key?(conn.private, :phoenix_controller) do
      raise Exception.PhoenixNotLoadedError
    end
  end

  def policy_module(module, suffix \\ "") do
    module_parts = Module.split(module)

    policy = module_parts
    |> List.last
    |> unsuffix(suffix)
    |> suffix("Policy")

    module_parts
    |> List.replace_at(length(module_parts) - 1, policy)
    |> Module.concat
  end

  @spec suffix(String.t, String.t) :: String.t
  def suffix(alias, suffix) do
    alias <> suffix
  end

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
