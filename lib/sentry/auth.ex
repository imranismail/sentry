defmodule Sentry.Auth do
  import Sentry.Helpers

  # Authorizer
  def authorize(conn, args) when is_list(args), do: authorize(conn, nil, args)
  def authorize(conn, resource) when is_map(resource), do: authorize(conn, nil, resource)

  def authorize(conn, action \\ nil, args \\ [])
  def authorize(conn, action, %Ecto.Changeset{} = changeset) do
    action = action || fetch_private!(conn, :phoenix_action)
    changeset.model.__struct__
    |> policy_module
    |> apply_policy(action, [conn, changeset])
  end
  def authorize(conn, action, args) when is_list(args) do
    action = action || fetch_private!(conn, :phoenix_action)
    conn
    |> fetch_private!(:phoenix_controller)
    |> policy_module("Controller")
    |> apply_policy(action, [conn] ++ args)
  end
  def authorize(conn, action, resource) when is_map(resource) do
    action = action || fetch_private!(conn, :phoenix_action)
    resource.__struct__
    |> policy_module
    |> apply_policy(action, [conn, resource])
  end
end
