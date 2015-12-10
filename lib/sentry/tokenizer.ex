defmodule Sentry.Tokenizer do
  import Comeonin.Bcrypt, only: [checkpw: 2, hashpwsalt: 1]

  def generate(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
  end

  def encrypt(token) do
    hashpwsalt(token)
  end

  def valid?(token, encrypted_token) do
    checkpw(token, encrypted_token)
  end

  def validate(token, encrypted_token, callback) when is_function(callback) do
    if checkpw(token, encrypted_token) do
      callback.()
    else
      {:error, "Invalid token"}
    end
  end
end
