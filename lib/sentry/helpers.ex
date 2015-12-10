defmodule Sentry.Helpers do
  import Sentry.Options, only: [uid_field: 0, password_field: 0]

  alias Ecto.Changeset
  alias Sentry.Exception

  def uid_from(%Changeset{} = changeset) do
    Changeset.get_change(changeset, uid_field)
  end

  def password_from(%Changeset{} = changeset) do
    Changeset.get_change(changeset, password_field)
  end

  def verify_policy!(policy) do
    if Code.ensure_loaded?(policy) do
      policy
    else
      raise Exception.UndefinedPolicyError, policy: policy
    end
  end

  def verify_phoenix_deps! do
    unless Code.ensure_loaded?(Phoenix) do
      raise Exception.PhoenixNotLoadedError
    end
  end

  def fetch_private!(conn, key) do
    if !!conn.private[key] do
      conn.private[key]
    else
      raise Exception.PrivateKeyNotLoadedError, key: key
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

  def apply_policy(policy, function, args) do
    policy
    |> verify_policy!
    |> apply(function, args)
  end

  def suffix(alias, suffix) do
    alias <> suffix
  end

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
