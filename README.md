# Sentry

Sentry provides a set of helpers and conventions that will guide you in leveraging Elixir modules to build a simple, robust authorization system.


## Installation
  1. Add sentry to your list of dependencies in `mix.exs`:

  ```elixir
    def deps do
      [{:sentry, "~> 0.1.1"}]
    end
  ```

  2. Ensure sentry is started before your application:

  ```elixir
  def application do
    [applications: [:sentry]]
  end
  ```

  3. Ensure your `User` model and `users` table has the following fields:
    - `:encrypted_password`
    - `email`
    - and a virtual `password` field.

  ```elixir
  # web/models/user.ex
  defmodule MyApp.User do
  use MyApp.Web, :model

    schema "users" do
      field :email, :string
      field :encrypted_password, :string
      field :password, :string, virtual: true
      field :password_confirmation, :string, virtual: true
      ...
      timestamps
    end
  end
  ```

  4. Configure Ueberauth and Sentry in `config/config.exs`
  ```elixir
  # config/config.exs

  # Ueberauth
  config :ueberauth, Ueberauth,
    providers: [
      identity: {Ueberauth.Strategy.Identity, [
        callback_methods: ["POST"]
      ]}
    ]

  # Sentry
  config :sentry, Sentry,
    repo: MyApp.Repo,
    model: MyApp.User # you may use a different model as you like
    # uid_field: :some_id_field \\ defaults to :email
    # password_field: :some_pw_field \\ defaults to :password
  ```

## Authentication
 For authentication please follow the following example, please refer to [Ueberatuh Readme](https://github.com/ueberauth/ueberauth) for more detail

 sentry provides the Sentry.Authenticator.attempt/1 method for authenticating users
 this uses the ueberauth_identity stratergy to collect useful information into
 the %Auth{} struct

 ```elixir
 # web/controllers/auth_controller

 defmodule MyApp.AuthController do
  use MyApp.Web, :controller
  import Sentry.Authenticator
  alias Ueberauth.Strategy.Helpers
  alias MyApp.User

  def request(conn, %{"provider" => "identity"} = _params) do
    render(conn, callback_url: Helpers.callback_url(conn),
      changeset: User.changeset(%User{}))
  end

  def request(conn, _params) do
    conn
    |> put_status(:not_found)
    |> render(MyApp.ErrorView, "404.html")
  end

  def callback(%{ assigns: %{ ueberauth_failure: fails } } = conn, _) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(conn, %{"provider" => "identity"}) do
    case attempt(conn) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "You've successfully logged in")
        |> redirect(to: "/")
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Helpers.request_path(conn))
    end
  end
  ```

  ```elixir
  # web/router.ex

  defmodule MyApp.Router do
  ...
    pipeline :auth do
      plug Ueberauth
    end

    scope "/auth", MyApp do
      pipe_through [:browser, :auth]

      get "/logout", AuthController, :delete
      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
      post "/:provider/callback", AuthController, :callback
    end
  end
  ```

  And last but not least the view

  ```elixir
  # web/templates/auth/request.html.eex
  <%= form_for @changeset, @callback_url, fn f -> %>
    <%= if f.errors != [] do %>
      <div class="alert alert-danger">
        <p>Oops, something went wrong! Please check the errors below:</p>
        <ul>
          <%= for {attr, message} <- f.errors do %>
            <li><%= humanize(attr) %> <%= message %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div class="form-group">
      <label>Email</label>
      <%= text_input f, :email, class: "form-control" %>
    </div>

    <div class="form-group">
      <label>Password</label>
      <%= password_input f, :password, class: "form-control" %>
    </div>

    <div class="form-group">
      <%= submit "Login", class: "btn btn-primary" %>
    </div>
  <% end %>
  ```

## Authorization
For authorization, we have 3 macros for dealing with it
 - `Sentry.Authorizer.authorize/2`
 - `Sentry.Authorizer.authorize_changeset/2`
 - `Sentry.Authorizer.authorize_changeset/3`

Let's say you would like to authorize a create post action based on a set of conditions
and it'll only authorize when those conditions are met.

```elixir
# web/controllers/post_controller.ex

defmodule MyApp.PostController do
  import Sentry.Authorizer
  alias MyApp.Repo
  alias MyApp.Post

  def update(conn, %{"id" => id, "post" => post_params}) do
    changeset = Repo.get!(Post, id)
    |> Post.changeset(params)

    authorize_changeset(conn, changeset)
  end
end
```

the `authorize_changeset/2` macro basically does this

```
unless MyApp.PostPolicy.update(conn, changeset) do
  raise Sentry.NotAuthorizedError
end
```

so, you can use something like [Plug.ErrorHandler](http://hexdocs.pm/plug/Plug.ErrorHandler.html) to handle these errors on the router level like maybe send them to a 401.html page?

```elixir
# web/policies/post_policy.ex

defmodule MyApp.PostPolicy do
  import Sentry.Authenticator

  def update(conn, changeset) do
    current_user = current_user(conn) # here we use Sentry.Authenticator.current_user helper to get the current user in the session

    changeset.params.post["user_id"] === current_user.id # Only authorize when the post belongs to the current user
  end
end
```

If you are not working on a changeset/resource you may opt to use the `Sentry.Authorizer.authorize/2` instead, the second optional argument can be used to pass data to the policy action. Do take not the `Sentry.Authorizer.authorize/2` will use the policy name based on the controller name.

for example: an action on `UserController.create` will use `UserPolicy.create`

## License

Sentry is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
