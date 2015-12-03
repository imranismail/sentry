defmodule Sentry.Authorizer do
  import Sentry.Helpers, only: [unsuffix: 2, suffix: 2]

  def authorize_changeset(conn, changeset, function \\ nil) do
    policy   = policy_module(changeset.model.__struct__)
    function = function || conn.private[:phoenix_action]

    apply_policy!(policy, function, [conn, changeset])
  end

  def authorize_changeset!(conn, changeset, function \\ nil) do
    policy   = policy_module(changeset.model.__struct__)
    function = function || conn.private[:phoenix_action]

    apply_policy!(policy, function, [conn, changeset])
  end

  def authorize(conn, opts \\ nil) do
    policy   = policy_module(conn.private[:phoenix_controller], "Controller")
    function = conn.private[:phoenix_action]

    apply_policy(policy, function, [conn, opts])
  end

  def authorize!(conn, opts \\ nil) do
    policy   = policy_module(conn.private[:phoenix_controller], "Controller")
    function = conn.private[:phoenix_action]

    apply_policy(policy, function, [conn, opts])
  end

  defp apply_policy(module, function, args) do
    check_policy!(module)

    case apply(module, function, args) do
      {:ok, result}    -> {:ok, result}
      {:error, reason} -> {:error, reason}
      _                -> raise Sentry.MatchError, module: module,
                                                    function: function,
                                                    arity: length(args)
    end
  end

  defp apply_policy!(module, function, args) do
    check_policy!(module)

    case apply(module, function, args) do
      {:ok, result}    -> result
      {:error, reason} -> raise Sentry.NotAuthorizedError, reason: reason
      _                -> raise Sentry.MatchError, module: module,
                                                    function: function,
                                                    arity: length(args)
    end
  end

  defp check_policy!(policy) do
    unless Code.ensure_loaded?(policy) do
      raise Sentry.UndefinedPolicyError, policy: policy
    end
  end

  defp policy_module(module, suffix \\ "") do
    module_parts = module |> Module.split

    policy = module_parts
    |> List.last
    |> unsuffix(suffix)
    |> suffix("Policy")

    module_parts
    |> List.replace_at(length(module_parts) - 1, policy)
    |> Module.concat
  end
end
