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
# web/controllers/auth_controller

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
  use Sentry, :view # this adds the logged_in?/1 and current_user/1 helper to the view
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
For authorization, we have 3 macros for dealing with it
- `Sentry.Authorizer.authorize/2`
- `Sentry.Authorizer.authorize_changeset/2`
- `Sentry.Authorizer.authorize_changeset/3`

Let's say a `PostController.Create` action should only be authorized when a set of conditions returns true.

```elixir
# web/controllers/post_controller.ex

defmodule MyApp.PostController do
  use Sentry, :authorizer

  alias MyApp.Repo
  alias MyApp.Post

  def update(conn, %{"id" => id, "post" => post_params}) do
    changeset = Repo.get!(Post, id)
    |> Post.changeset(params)

    authorize_changeset(conn, changeset) # you may optionally override the function to be executed on the policy module by passing a third argument. Example: :create
  end
end
```

the `authorize_changeset/2` macro basically does this

```elixir
case MyApp.PostPolicy.update(conn, changeset) do
  false  -> raise Sentry.NotAuthorizedError
  result -> result
end
```

```elixir
# web/policies/post_policy.ex

defmodule MyApp.PostPolicy do
  use Sentry, :authenticator

  def update(conn, changeset) do
    current_user = current_user(conn) # here we use Sentry.Authenticator.current_user helper to get the current user in the session

    changeset.params.post["user_id"] === current_user.id # Only authorize when the post belongs to the current user
  end
end
```

### Authorization without resource/changeset

If you are not working on a changeset/resource you may opt to use the `Sentry.Authorizer.authorize/2` instead, the second optional argument can be used to pass data to the policy action.

Do take note the `Sentry.Authorizer.authorize/2` will use the policy name based on the controller name.

For example: an action on `UserController.create` will use `UserPolicy.create`

```elixir
# web/controllers/user_controller.ex

defmodule UserController do
  use Sentry, :authorizer

  def create(conn, params) do
    authorize(conn, params)
  end
end
```

```elixir
# web/policies/user_policy.ex

defmodule UserPolicy do
  def create(conn, opts) do
    true
  end
end
```

## Error Handling
To handle the errors raised by `Sentry.Authorizer.authorize`, we can use something like [Plug.ErrorHandler](http://hexdocs.pm/plug/Plug.ErrorHandler.html). This can either be plugged at the router level or controller.

## License

Sentry is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
