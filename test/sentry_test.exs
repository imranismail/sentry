defmodule UserController do
  use Sentry

  def create(_conn, resource) do
    authorize(resource)
  end
end

defmodule UserPolicy do
  def create(resource) do
    {:ok, resource}
  end
end

defmodule SentryTest do
  use ExUnit.Case
  doctest Sentry

  test "a user resource action should use equivalent policy" do
    assert {:ok, resource} = UserController.create("connection", %{name: "Imran"})
  end
end
