# Sentry

Sentry provides a set of helpers and conventions that will guide you in leveraging Elixir modules to build a simple, robust authorization system.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add sentry to your list of dependencies in `mix.exs`:

        def deps do
          [{:sentry, github: "imranismail/sentry", branch: "develop"}]
        end

  2. Ensure sentry is started before your application:

        def application do
          [applications: [:sentry]]
        end

  3. Configure repo and model in config/config.exs

        config :sentry, Sentry,
          repo: Bonsai.Repo,
          model: Bonsai.User

  4. Optionally configure Ueberauth for Authentication
        config :ueberauth, Ueberauth,
          providers: [
            identity: {Ueberauth.Strategy.Identity, [
              callback_methods: ["POST"]
            ]}
          ]

  5. Ensure user table has `:encrypted_password` field

## Usage

 1. For authentication, please refer to [Ueberatuh Readme](https://github.com/ueberauth/ueberauth)

 Basically we need a request and callback method and we are using the `:identity` stratergy for username/password authentication

 Sentry makes this much, much easier by providing additional helper library on top of Ueberauth see `Sentry.Authenticator` for more information

 2. For authorization, we have 3 macros for dealing with it
    - `Sentry.Authorizer.authorize/2`
    - `Sentry.Authorizer.authorize_changeset/2`
    - `Sentry.Authorizer.authorize_changeset/3`

        defmodule MyApp.PostController do
          use Sentry

          def create(conn, params) do
            changeset = Post.changeset(%Post{}, params)
            authorize(conn, changeset)
          end
        end

        defmodule MyApp.PostPolicy do
          use Sentry

          def update(conn, changeset) do
            current_user = current_user(conn)
            changeset.params.user_id === current_user.id
          end
        end
