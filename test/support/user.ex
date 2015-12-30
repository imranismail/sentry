defmodule Sentry.User do
  use Ecto.Model
  use Sentry, :model

  import Ecto.Changeset
  # import Ecto.Query, only: [from: 1, from: 2]

  schema "users" do
    # Authenticatable
    field :email, :string
    field :password, :string, virtual: true
    field :encrypted_password, :string

    # Recoverable
    field :reset_password_token, :string
    field :reset_password_generated_at, Ecto.DateTime

    # Rememberable
    field :remember_created_at, Ecto.DateTime

    # Trackable
    field :sign_in_count, :integer, default: 0
    field :current_sign_in_at, Ecto.DateTime
    field :last_sign_in_at, Ecto.DateTime
    field :current_sign_in_ip, :string
    field :last_sign_in_ip, :string

    # Confirmable
    field :confirmation_token, :string
    field :confirmation_generated_at, Ecto.DateTime
    field :confirmed_at, Ecto.DateTime
    field :unconfirmed_email, :string # Only if using reconfirmable

    # Lockable
    field :failed_attempts, :integer, default: 0 # Only if lock strategy is :failed_attempts
    field :unlock_token, :string # Only if unlock strategy is :email or :both
    field :locked_at, Ecto.DateTime

    timestamps
  end

  @required_fields ~w(email password)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:email)
    |> validate_length(:password, min: 1)
    |> validate_confirmation(:password)
  end
end
