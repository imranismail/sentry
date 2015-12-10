defmodule Sentry.AuthTest do
  use Sentry.Case
  import Sentry.Auth, only: [encrypt_password: 1, attempt: 1]

  setup do
    user_params = %{"email" => "imran.codely@gmail.com", "password" => "password"}
    {:ok, user_params: user_params}
  end

  test "verify configuration" do
    config = [
      repo: Sentry.Repo,
      model: Sentry.User,
      uid_field: :email,
      password_field: :password
    ]

    assert Application.get_env(:sentry, Sentry) == config
  end

  test "encrypt password", context do
    changeset = User.changeset(%User{}, context[:user_params])
    assert changeset.valid?

    changeset = changeset |> encrypt_password
    assert !!get_change(changeset, :encrypted_password) == true
  end

  test "authenticate user", context do
    User.changeset(%User{}, context[:user_params])
    |> encrypt_password
    |> Repo.insert

    invalid_params = %{context[:user_params] | "password" => "invalidpassword"}
    assert {:error, %Ecto.Changeset{}} = attempt(invalid_params)

    valid_params = context[:user_params]
    assert {:ok, %User{}} = attempt(valid_params)
  end
end
