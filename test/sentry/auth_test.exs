defmodule Sentry.AuthTest do
  use Sentry.Case

  alias Sentry.Auth
  alias Sentry.User
  alias Sentry.Repo

  @valid_attrs %{email: "foo@example.com",
                 password: "password",
                 password_confirmation: "password"}

  test "verify configuration" do
    config = [repo: Sentry.Repo, model: Sentry.User]
    assert Application.get_env(:sentry, Sentry) == config
  end

  test "user insertion should encrypt password" do
    assert {:ok, user} =
      %User{}
      |> User.changeset(@valid_attrs)
      |> Auth.encrypt_changes(:password, :encrypted_password)
      |> Repo.insert
    assert user.encrypted_password !== user.password
  end

  test "attempt with valid password" do
    assert {:ok, _user} =
      %User{}
      |> User.changeset(@valid_attrs)
      |> Auth.encrypt_changes(:password, :encrypted_password)
      |> Repo.insert
    assert {:ok, %User{}} = Auth.attempt(@valid_attrs)
  end

  test "attempt with invalid password" do
    assert {:ok, _user} =
      %User{}
      |> User.changeset(@valid_attrs)
      |> Auth.encrypt_changes(:password, :encrypted_password)
      |> Repo.insert
    invalid_attrs = %{@valid_attrs | password: "thisisnotavalidpassword"}
    assert @valid_attrs.password !== invalid_attrs.password
    assert {:error, changeset} = Auth.attempt(invalid_attrs)
    assert {:password,
            "no matching password found"}
           in changeset.errors
  end

  test "attempt with invalid email" do
    assert {:ok, _user} =
      %User{}
      |> User.changeset(@valid_attrs)
      |> Auth.encrypt_changes(:password, :encrypted_password)
      |> Repo.insert
    invalid_attrs = %{@valid_attrs | email: "bar@example.com"}
    assert invalid_attrs.email !== @valid_attrs.email
    assert {:error, changeset} = Auth.attempt(invalid_attrs)
    assert {:email, "can't find user with that email"} in changeset.errors
  end
end
