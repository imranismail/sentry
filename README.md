# Sentry

"Sentry provides a set of helpers and conventions that will guide you in leveraging Elixir modules to build a simple, robust authorization system." - Inspired by [elabs/pundit](https://github.com/elabs/pundit)

## TODOs
- Generators
- JWT

## Installation
Add sentry to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:sentry, "~> 0.1"}]
end
```

Ensure sentry is started before your application:

```elixir
def application do
  [applications: [:sentry]]
end
```

Ensure your `User` model and `users` table has the following fields:
  - `:encrypted_password` field
  - a user identification field. Defaults to `email`
  - and a virtual password field. Defaults to `password`

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

Configure Ueberauth and Sentry in `config/config.exs`
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
Sentry leverages [ueberauth](https://github.com/ueberauth/ueberauth) for the authentication layer with an addition of bcrypt encryption when storing and authenticating user.

Sentry provides useful helpers for working with users on your system

- `Sentry.Authenticator.attempt/1`
- `Sentry.Authenticator.logout/1`
- `Sentry.Authenticator.encrypt_password/1`
- `Sentry.Authenticator.logged_in?/1`
- `Sentry.Authenticator.current_user/1`

here's an example use case

```elixir
# web/controllers/auth_controller.ex

defmodule MyApp.AuthController do
  use MyApp.Web, :controller
  use Sentry, :authenticator

  alias MyApp.User

  def request(conn, %{"provider" => "identity"} = _params) do
    render(conn, callback_url: callback_url(conn),
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
    # attempts to authorize user
    # once authorized you can then access the user info with
    # `Sentry.Authenticator.current_user/1`
    # or check if logged in with `Sentry.Authenticator.logged_in?/1`
    case attempt(conn) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "You've successfully logged in")
        |> redirect(to: "/")
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: request_path(conn))
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You've been logged out!")
    |> logout()
    |> redirect(to: "/")
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

```elixir
# web/view/layout_view.ex
defmodule MyApp.LayoutView do
  use MyApp.Web, :view
  # this adds the logged_in?/1 and current_user/1 helper to the view
  use Sentry, :view
end
```

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
For authorization, we have the following functions for dealing with it

- `Sentry.Authorizer.authorize/2`
- `Sentry.Authorizer.authorize_changeset/3`
- `Sentry.Authorizer.authorize!/2`
- `Sentry.Authorizer.authorize_changeset!/3`

The bang functions follows Elixir's [convention](http://elixir-lang.org/getting-started/try-catch-and-rescue.html#errors) of throwing exceptions and returning values instead of returning tuples like {:ok, result} or {:error, reason}

```elixir
# web/controllers/auth_controller.ex

defmodule MyApp.AuthController do
  use MyApp.Web, :controller
  use Sentry, :authenticator

  alias MyApp.User

  def request(conn, %{"provider" => "identity"} = _params) do
    # you may pass an optional second parameter as
    # a data that is then accessable on the `AuthPolicy.request/2` action
    case authorize(conn) do
      {:ok, conn} ->
        render(conn, callback_url: callback_url(conn),
               changeset: User.changeset(%User{}))
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
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
    # attempts to authorize user
    # once authorized you can then access the user info with
    # `Sentry.Authenticator.current_user/1`
    # or check if logged in with `Sentry.Authenticator.logged_in?/1`
    case attempt(conn) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "You've successfully logged in")
        |> redirect(to: "/")
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: request_path(conn))
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You've been logged out!")
    |> logout()
    |> redirect(to: "/")
  end
end
```

or you can use it as a plug function or even cleaner module

```elixir
defmod MyApp.AuthController do
  ...

  plug :authorize_action when action in [:request]

  def request(conn, _params) do
    ...
  end

  def authorize_action (conn, _options) do
    case authorize(conn) do
      {:ok, conn} ->
        conn
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end
end
```

```elixir
# web/policies/auth_policy.ex

defmodule MyApp.AuthPolicy do
  use Sentry, :authenticator

  def request(conn, options) do
    # `logged_in?/1` is a helper function from
    # `Sentry.Authenticator` that checks if a user is logged in
    if logged_in?(conn) do
      {:ok, conn}
    else
      {:error, "You're already logged in"}
    end
  end
end
```

### Authorizing resource/changeset

If you are working on resource/changeset, you might want to use the `Sentry.Authorizer.authorize_changeset/2` function as it will use a policy based on the model name
you can also use `authorize_changeset/2` with plugs.

```elixir
# web/controllers/user_controller.ex

defmodule PostController do
  use Sentry, :authorizer

  alias MyApp.Post

  def update(conn, %{"id" => id, "post" => post_params}) do
    changeset = Post.changeset(post, post_params)
    # you can pass an optional third argument as an
    # atom to override the function
    # to be executed on the policy for example:
    # authorize_changeset(conn, changeset, :belongs_to_current_user)
    # this will instead run the
    # `PostPolicy.belongs_to_current_user/2` action
    authorize_changeset(conn, changeset)
  end
end
```

```elixir
# web/policies/post_policy.ex

defmodule PostPolicy do
  use Sentry, :authenticator

  def update(conn, changeset) do
    ...
  end

  def belongs_to_current_user(conn,
                          %Ecto.Changeset{params: %{user_id: user_id}}) do
    if current_user(conn).id === user_id do
      {:ok, conn}
    else
      {:error, "You're not authorized to edit this post}
    end
  end
end
```

## License

Sentry is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
