defmodule MyApp.User do
  defstruct name: nil, age: nil, email: nil
end

defmodule MyApp.UserController do
  use Sentry

  def create(conn, resource) do
    authorize(conn, resource)
  end
end

defmodule MyApp.UserPolicy do
  def create(conn, resource) do
    {:ok, resource}
  end
end

defmodule SentryTest do
  use ExUnit.Case
  doctest Sentry

  test "a resource controller action should use similarly named resource policy action" do
    user = %MyApp.User{name: "John Doe", age: 23, email: "john.doe@example.com"}
    conn = "this should be the %Plug.Conn{} struct"
    assert {:ok, _resource} = MyApp.UserController.create(conn, user)
  end
end
