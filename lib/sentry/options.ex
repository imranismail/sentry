defmodule Sentry.Options do
  def model, do: from_options(:model)

  def repo, do: from_options(:repo)

  def authentication_key, do: from_options(:authentication_key) || :email

  def from_options(key) do
    options = Application.get_env(:sentry, Sentry)
    if options, do: options[key], else: nil
  end
end
