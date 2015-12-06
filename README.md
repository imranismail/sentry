# Sentry

"Sentry provides a set of helpers and conventions that will guide you in leveraging Elixir modules to build a simple, robust authorization system." - Inspired by [elabs/pundit](https://github.com/elabs/pundit)

## TODOs
- Generators

## Installation
Add sentry to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:sentry, "~> 0.3"}]
end
```

For authentication, ensure your `User` model and `users` table has the following fields:
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

Configure Sentry
```elixir
# config/config.exs

config :sentry, Sentry,
  repo: MyApp.Repo,
  model: MyApp.User # you may use a different model as you like
  # uid_field: :some_id_field \\ defaults to :email
  # password_field: :some_pw_field \\ defaults to :password
```

## Authentication
Sentry provides useful helpers for working with users on your system

- `Authenticator.encrypt_password/1`
- `Authenticator.attempt/1`

### Authenticator.encrypt_password/1
Is used to encrypt the password field and add it to the changeset as 'encrypted_password'. Here's an example of a user creation

```elixir
def create_user(conn, %{"user" => user_params}) do
  changeset = User.changeset(%User{}, user_params)
  |> Authenticator.encrypt_password

  case Repo.insert(changeset) do
    {:ok, new_user} ->
      conn
      |> put_flash(:info, "You've successfully registered")
      |> Guardian.Plug.sign_in(new_user, :token)
      |> redirect(to: "/")
    {:error, changeset} ->
      render(conn, "register.html", changeset: changeset)
  end
end
```

### Authenticator.attempt/1
Is used to attempt an authentication on a resource as specified in `config.exs`. In this example we used [guardian](https://github.com/hassox/guardian) to store the resource session using JWT. You can also just use `put_session`.

```elixir
# web/controllers/session_controller.ex

# Authenticator accepts the user params and tries to authenticate
# returning {:ok, authenticated_user} or {:error, changeset}
# you can then use the changeset to show authentication errors
def log_user_in(conn, %{"user" => user_params}) do
  case Sentry.Authenticator.attempt(user_params) do
    {:ok, user} ->
      conn
      |> put_flash(:info, "You've successfully logged in")
      |> Guardian.Plug.sign_in(user, :token)
      |> redirect(to: "/")
    {:error, changeset} ->
      conn
      |> render("login.html", changeset: changeset)
  end
end
```

## Authorization
For authorization, we have the following functions for dealing with it

- `Authorizer.authorize/1`
- `Authorizer.authorize/2`
- `Authorizer.authorize/3`

Let's say that we have an `index` action in `page_controller.ex` that we only allow users who are logged in to be able to access.

There's a few way to do this. One is just as a normal `authorize/1` function

```elixir
# web/controllers/page_controller.ex

defmodule MyApp.PageController do
  use Sentry, :authorizer # Make sure this line is included

  def index(conn, _params) do
    # you can optionally pass a second argument
    # to be used in the policy example: authorize(conn, params)
    case authorize(conn) do
      {:ok, conn} ->
        render(conn, "index.html")
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end
end
```

Or you can use it as a plug function in Phoenix controllers

```elixir
# web/controllers/page_controller.ex

defmodule MyApp.PageController do
  ...
  use Sentry, :authorizer # Make sure this line is included

  plug :authorize_action when action in [:index]

  def index(conn, _params) do
    ...
  end

  def authorize_action(conn, _options) do
    # you can optionally pass a second argument
    # to be used in the policy example: authorize(conn, options)
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

This will invoke a policy action based on the module name and action name, in the above example `authorize/1` will invoke the `SessionPolicy.index` which must return a tuple of `{:ok, conn} | {:error, reason}`

Let's write a policy for the `PageController.index/2` action

```elixir
# web/policies/page_policy.ex

defmodule MyApp.PagePolicy do
  # the `option` argument is supplied if we use `authorize/2`
  # if not it will be `nil`

  def index(conn, _option) do
    # Let's return {:ok, conn} if the user is logged in
    # Otherwise return {:error, reason} if user is not logged in
    # Let's assume that we have a `:current_user` stored in the session
    # if the user is logged in
    if !!get_session(conn, :current_user) do
      {:ok, conn}
    else
      {:error, "You're already logged in"}
    end
  end
end
```

### Authorizing resource/changeset

If you are working on resource/changeset, sentry is clever enough to use a policy named after the resource instead of the module it is authorizing, the function name however will use the action it is authorizing. Do take note that the function name is overridable if we pass a third argument.

Example:

```elixir
  def update(conn, %{"id" => id, "post" => post_params}) do
    ...
    changeset = Post.changeset(post, post_params)
    # you can pass an optional third argument as an
    # atom to override the function
    # to be executed on the policy for example:
    # authorize(conn, changeset, :belongs_to_current_user)
    # this will instead run the
    # `PostPolicy.belongs_to_current_user/2` action
    authorize(conn, changeset)
    ...
  end
```

Which in turn will use a policy named after the model. In this case the `Post` model will use the `PostPolicy` policy

```elixir
# web/policies/post_policy.ex

defmodule PostPolicy do
  use Sentry, :authenticator

  def update(conn, changeset) do
    ...
  end
end
```

## Headless policy
Sometimes you just want to authorize a couple of actions using the same policy again and again. In this case using a headless policy and a plug module might be more suitable.

We can authorize the same policy by passing the policy module and action in the second and third argument.

Let's create a plug to demonstrate
```
# web/plugs/ensure_authenticated.ex

defmodule MyApp.EnsureAuthenticated do
  @behaviour Plug

  import Sentry.Authorizer, only: [authorize: 3] # we don't use `use` in this case.
  import Phoenix.Controller

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    # authorize(conn, policy, function_name: [arguments])
    case authorize(conn, MyApp.SessionPolicy, authenticated: opts) do
      {:ok, conn} ->
        conn
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/login")
    end
  end
end
```

and the policy for the above plug

```
# web/policies/session_policy.ex

defmodule MyApp.SessionPolicy do
  def authenticated(conn, opts) do
    if !!current_resource(conn) do
      {:ok, conn}
    else
      {:error, "You're not signed in"}
    end
  end
end
```

Now we can use the plug in multiple places. Let's rewrite our page controller to use this plug

```
# web/controller/page_controller.ex

defmodule MyApp.PageController do
  ...
  plug MyApp.EnsureAuthenticated

  def index(conn, _params) do
   render(conn, "index.html")
  end
end
```


## License

Sentry is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
