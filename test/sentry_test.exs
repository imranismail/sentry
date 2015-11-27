defmodule MyApp.UserController do
  use Sentry

  def create(_conn, resource) do
    authorize(resource)
  end
end

defmodule MyApp.UserPolicy do
  def create(resource) do
    {:ok, resource}
  end
end

defmodule SentryTest do
  use ExUnit.Case
  doctest Sentry

  test "a user resource action should use similarly named policy" do
    assert {:ok, resource} = MyApp.UserController.create("conn", %{name: "Imran"})
  end
end
