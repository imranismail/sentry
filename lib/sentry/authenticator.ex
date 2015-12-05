defmodule Sentry.Authenticator do
  alias Ecto.Changeset
  alias Comeonin.Bcrypt

  def attempt(params) do
    changeset = changeset(params)
    if changeset.valid? do
      repo.get_by(model, [{uid_field, uid(changeset)}])
      |> validate_password(changeset)
    else
      {:error, changeset}
    end
  end

  def encrypt_password(changeset) do
    if changeset.valid? do
      Changeset.put_change(changeset, :encrypted_password, Bcrypt.hashpwsalt(changeset.params["#{password_field}"]))
    else
      changeset
    end
  end

  defp changeset(params) do
    struct(model)
    |> Changeset.cast(params, ["#{uid_field}", "#{password_field}"], [])
  end

  defp validate_password(nil, changeset) do
    {:error, Changeset.add_error(changeset,
                                 :email,
                                 "can't find user with that email address")}
  end

  defp validate_password(user, changeset) do
    case Bcryot.checkpw(password(changeset), user.encrypted_password) do
      true  -> {:ok, user}
      _     -> {:error, Changeset.add_error(changeset,
                                            :password,
                                            "no matching password found")}
    end
  end

  defp model, do: from_options(:model)

  defp repo, do: from_options(:repo)

  defp uid_field, do: from_options(:uid_field) || :email

  defp password_field, do: from_options(:password_field) || :password

  defp uid(changeset), do: Changeset.get_change(changeset, uid_field)

  defp password(changeset), do: Changeset.get_change(changeset, password_field)

  defp from_options(key) do
    options = Application.get_env(:sentry, Sentry)
    if options, do: options[key], else: nil
  end
end
