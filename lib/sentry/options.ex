defmodule Sentry.Options do
  def model, do: from_options(:model)

  def repo, do: from_options(:repo)

  def uid_field, do: from_options(:uid_field) || :email

  def password_field, do: from_options(:password_field) || :password

  def from_options(key) do
    options = Application.get_env(:sentry, Sentry)
    if options, do: options[key], else: nil
  end
end
