defmodule Sentry.Auth do
  import Ecto.Changeset, only: [cast: 4, add_error: 3, put_change: 3, change: 2]
  import Comeonin.Bcrypt, only: [checkpw: 2, hashpwsalt: 1]
  import Sentry.Options
  import Sentry.Helpers

  # Authenticator
  def attempt(user_params, user \\ nil) do
    changeset = authentication_changeset(user_params)
    if changeset.valid? do
      user = user || repo.get_by(model, [{authentication_key,
                                          changeset.changes[authentication_key]}])
      validate_password(user, changeset)
    else
      {:error, changeset}
    end
  end

  defp authentication_changeset(user_params) do
    model.__struct__
    |> cast(user_params, [authentication_key, :password], [])
  end

  defp validate_password(nil, changeset) do
    {:error, add_error(changeset,
                       authentication_key,
                       "can't find user with that #{authentication_key}")}
  end
  defp validate_password(user, changeset) do
    case checkpw(changeset.changes.password, user.encrypted_password) do
      true  -> {:ok, user}
      _     -> {:error, add_error(changeset,
                                  :password,
                                  "no matching password found")}
    end
  end

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

  # Encryption
  def encrypt_changes(changeset, from) do
    change_to_encrypt = changeset.changes[from]
    if change_to_encrypt do
      put_change(changeset, from, hashpwsalt(change_to_encrypt))
    else
      changeset
    end
  end

  def encrypt_changes(changeset, from, to) do
    change_to_encrypt = changeset.changes[from]
    if change_to_encrypt do
      put_change(changeset, to, hashpwsalt(change_to_encrypt))
    else
      changeset
    end
  end
end
