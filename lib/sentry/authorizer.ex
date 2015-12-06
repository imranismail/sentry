defmodule Sentry.Authorizer do
  alias Ecto.Changeset
  alias Sentry.Exception

  def authorize(conn, arg \\ nil, function \\ nil)

  def authorize(conn, module, [{function, args}]) do
    apply_policy(module, function, [conn, args])
  end

  def authorize(conn, %Changeset{} = arg, function) do
    policy   = policy_module(arg.model.__struct__)
    function = function || conn.private[:sentry_function]

    apply_policy(policy, function, [conn, arg])
  end

  def authorize(conn, arg, _function) do
    policy   = policy_module(conn.private[:sentry_module], "Controller")
    function = conn.private[:sentry_function]

    apply_policy(policy, function, [conn, arg])
  end

  defp apply_policy(module, function, args) do
    check_policy!(module)

    case apply(module, function, args) do
      {:ok, result}    -> {:ok, result}
      {:error, reason} -> {:error, reason}
      _                -> raise Exception.MatchError, module: module,
                                                      function: function,
                                                      arity: length(args)
    end
  end

  defp check_policy!(policy) do
    if Code.ensure_loaded?(policy) do
      policy
    else
      raise Exception.UndefinedPolicyError, policy: policy
    end
  end

  defp policy_module(module, suffix \\ "") do
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
  defp suffix(alias, suffix) do
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
