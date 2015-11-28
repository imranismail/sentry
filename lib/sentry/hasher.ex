defmodule Sentry.Hasher do
  import Ecto.Changeset, only: [put_change: 3]
  import Comeonin.Bcrypt, only: [hashpwsalt: 1, checkpw: 2]

  @doc """
  Generates a password for the user changeset from the "password" params and stores it to the changeset as encrypted_password.
  """
  def hash(changeset) do
    put_change(changeset, :encrypted_password, hashpwsalt(changeset.params["password"]))
  end

  @doc """
  Checks if a password is valid
  """
  def valid?(resource, password) do
    checkpw(password, resource.encrypted_password)
  end
end
