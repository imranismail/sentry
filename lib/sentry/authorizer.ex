defmodule Sentry.Authorizer do
  alias Ecto.Changeset
  alias Sentry.Helpers

  def authorize(conn, arg \\ nil, function \\ nil)
  def authorize(conn, module, [{function, args}]) do
    Helpers.apply_policy(module, function, [conn] ++ [args])
  end
  def authorize(conn, %Changeset{} = changeset, function) do
    Helpers.verify_phoenix_controller!(conn)
    policy   = Helpers.policy_module(changeset.model.__struct__)
    function = function || conn.private[:phoenix_controller]
    Helpers.apply_policy(policy, function, [conn, changeset])
  end
  def authorize(conn, args, function) do
    Helpers.verify_phoenix_controller!(conn)
    policy   = Helpers.policy_module(conn.private[:phoenix_controller],
                             "Controller")
    function = function || conn.private[:phoenix_action]
    Helpers.apply_policy(policy, function, [conn] ++ [args])
  end
end
