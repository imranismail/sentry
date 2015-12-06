defmodule Sentry.Authenticator do
  alias Ecto.Changeset
  alias Comeonin.Bcrypt
  alias Sentry.Helpers
  alias Sentry.Options

  def attempt(params) do
    changeset = changeset(params)
    if changeset.valid? do
      Options.repo.get_by(Options.model, [{Options.uid_field,
                           Helpers.uid_from(changeset)}])
      |> validate_password(changeset)
    else
      {:error, changeset}
    end
  end

  def encrypt_password(changeset) do
    if changeset.valid? do
      Changeset.put_change(changeset, :encrypted_password, Bcrypt.hashpwsalt(changeset.params["#{Options.password_field}"]))
    else
      changeset
    end
  end

  def changeset(params) do
    struct(Options.model)
    |> Changeset.cast(params, ["#{Options.uid_field}",
                               "#{Options.password_field}"], [])
  end

  defp validate_password(nil, changeset) do
    {:error, Changeset.add_error(changeset,
                                 :email,
                                 "can't find user with that email address")}
  end
  defp validate_password(user, changeset) do
    case Bcrypt.checkpw(Helpers.password_from(changeset),
                        user.encrypted_password) do
      true  -> {:ok, user}
      _     -> {:error, Changeset.add_error(changeset,
                                            :password,
                                            "no matching password found")}
    end
  end
end
