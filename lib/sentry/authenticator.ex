defmodule Sentry.Authenticator do
  import Plug.Conn, only: [get_session: 2, delete_session: 2]

  alias Ecto.Changeset
  alias Comeonin.Bcrypt
  alias Ueberauth.Auth
  alias Ueberauth.Auth.Credentials

  def attempt(%Auth{provider: :identity} = auth) do
    validate_authenticity(auth)
  end

  def current_user(conn) do
    get_session(conn, :current_user)
  end

  def logged_in?(conn), do: !!get_session(conn, :current_user)

  def logout(conn), do: delete_session(conn, :current_user)

  def encrypt_password(changeset) do
    Changeset.put_change(changeset, :encrypted_password, Bcrypt.hashpwsalt(changeset.params["password"]))
  end

  def validate_authenticity(auth) do
    opts = Application.get_env(:sentry, Sentry)

    %Auth{credentials:
      %Credentials{
        other: %{password: password}},
      uid: email} = auth

    case {email, password} do
      {"", ""} ->
        {:error, "Please fill in the empty fields"}
      {_email, ""} ->
        {:error, "Password is required"}
      {"", _password} ->
        {:error, "Email is required"}
      {email, password} ->
        user = opts[:repo].get_by(opts[:model], email: email)
        validate_password(user, password)
    end
  end

  defp validate_password(nil, _password), do: {:error, "User not found"}
  defp validate_password(user, password) do
    case Bcrypt.checkpw(password, user.encrypted_password) do
      true  -> {:ok, user}
      _     -> {:error, "Invalid username/password"}
    end
  end
end
