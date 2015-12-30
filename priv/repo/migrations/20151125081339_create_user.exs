defmodule Sentry.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      # Authenticatable
      add :email, :string, null: false, default: ""
      add :encrypted_password, :string, null: false, default: ""

      # Rememberable
      add :remember_created_at, :datetime

      # Trackable
      add :sign_in_count, :integer, null: false, default: 0
      add :current_sign_in_at, :datetime
      add :last_sign_in_at, :datetime
      add :current_sign_in_ip, :string
      add :last_sign_in_ip, :string

      # Confirmable
      add :confirmed_at, :datetime
      add :unconfirmed_email, :string # Only if using reconfirmable

      # Lockable
      add :failed_attempts, :integer, null: false, default: 0 # Only if lock strategy is :failed_attempts
      add :unlock_token, :string # Only if unlock strategy is :email or :both
      add :locked_at, :datetime

      timestamps
    end

    create index(:users, [:email], unique: true)
    create index(:users, [:reset_password_token], unique: true)
  end
end
