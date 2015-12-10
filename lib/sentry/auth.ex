defmodule Sentry.Auth do
  import Ecto.Changeset, only: [put_change: 3, cast: 4, add_error: 3]
  import Comeonin.Bcrypt, only: [checkpw: 2, hashpwsalt: 1]
  import Sentry.Options
  import Sentry.Helpers

  # Authenticator
  def attempt(params) do
    changeset = changeset(params)
    if changeset.valid? do
      repo.get_by(model, [{uid_field, uid_from(changeset)}])
      |> validate_password(changeset)
    else
      {:error, changeset}
    end
  end

  def encrypt_password(changeset) do
    if changeset.valid? do
      put_change(changeset,
                 :encrypted_password,
                 hashpwsalt(changeset.params["#{password_field}"]))
    else
      changeset
    end
  end

  defp changeset(params) do
    struct(model)
    |> cast(params, ["#{uid_field}", "#{password_field}"], [])
  end

  defp validate_password(nil, changeset) do
    {:error, add_error(changeset,
                       :email,
                       "can't find user with that email address")}
  end
  defp validate_password(user, changeset) do
    case checkpw(password_from(changeset), user.encrypted_password) do
      true  -> {:ok, user}
      _     -> {:error, add_error(changeset,
                                  :password,
                                  "no matching password found")}
    end
  end

  # Authorizer
  def authorize(conn, args) when is_list(args), do: authorize(conn, nil, args)
  def authorize(conn, resource) when is_map(resource), do: authorize(conn, nil, resource)

  def authorize(conn, function \\ nil, args \\ [])
  def authorize(conn, function, %Ecto.Changeset{} = changeset) do
    function = function || fetch_private!(conn, :phoenix_action)
    policy_module(changeset.model.__struct__)
    |> apply_policy(function, [conn, changeset])
  end
  def authorize(conn, function, args) when is_list(args) do
    function = function || fetch_private!(conn, :phoenix_action)
    conn
    |> fetch_private!(:phoenix_controller)
    |> policy_module("Controller")
    |> apply_policy(function, [conn] ++ args)
  end
  def authorize(conn, function, model) when is_map(model) do
    function = function || fetch_private!(conn, :phoenix_action)
    policy_module(model.__struct__)
    |> apply_policy(function, [conn, model])
  end
end
