defmodule SentryTest do
  use ExSpec
  doctest Sentry

  use Plug.Test

  describe "testing plug" do
    defmodule SlimApp do
      defmodule UsersPolicy do
        def show?(conn) do
          true
        end

        def edit(conn) do
          conn
        end
      end

      defmodule UsersController do
        use Plug.Builder
        plug Sentry, policy: UsersPolicy
      end
    end

    it "works when phoenix private fields are present" do
      conn = conn(:get, "/")
        |> put_private(:phoenix_action, :edit)
        |> put_private(:phoenix_controller, SlimApp.UsersController)

      conn = conn |> SlimApp.UsersController.call([])
    end


    it "raises when phoenix private fields are absent" do
      conn = conn(:get, "/")
      assert_raise Sentry.Exception.PrivateKeyNotLoadedError, fn ->
        conn |> SlimApp.UsersController.call([])
      end
    end

    it "raises when phoenix private fields are partially present" do
      conn = conn(:get, "/")
        |> put_private(:phoenix_action, :edit)
      assert_raise Sentry.Exception.PrivateKeyNotLoadedError, fn ->
        conn |> SlimApp.UsersController.call([])
      end

      conn = conn(:get, "/")
        |> put_private(:phoenix_controller, SlimApp.UsersController)
      assert_raise Sentry.Exception.PrivateKeyNotLoadedError, fn ->
        conn |> SlimApp.UsersController.call([])
      end
    end

  end
end
