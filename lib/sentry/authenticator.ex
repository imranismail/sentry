defmodule Sentry.Authenticator do
  import Sentry.Helpers

  alias Plug.Conn
  alias Ecto.Changeset
  alias Comeonin.Bcrypt

  def attempt(conn) do
    case validate_authenticity(uid(conn), password(conn)) do
      {:ok, user}      -> {:ok, Conn.put_session(conn, :current_user, user)}
      {:error, reason} -> {:error, reason}
    end
  end

  def current_user(conn) do
    Conn.get_session(conn, :current_user)
  end

  def logged_in?(conn), do: !!Conn.get_session(conn, :current_user)

  def logout(conn), do: Conn.delete_session(conn, :current_user)

  def encrypt_password(changeset) do
    Changeset.put_change(changeset, :encrypted_password, Bcrypt.hashpwsalt(changeset.params["password"]))
  end

  defp validate_authenticity("", ""), do: {:error, "Please fill in the empty fields"}
  defp validate_authenticity(_uid, ""), do: {:error, "Password is required"}
  defp validate_authenticity("", _password), do: {:error, "Identification is required"}
  defp validate_authenticity(uid, password) do
    repo.get_by(model, [{uid_key(), uid}])
    |> validate_password(password)
  end

  defp validate_password(nil, _password), do: {:error, "User not found"}
  defp validate_password(user, password) do
    case Bcrypt.checkpw(password, user.encrypted_password) do
      true  -> {:ok, user}
      _     -> {:error, "No matching password found"}
    end
  end
end
