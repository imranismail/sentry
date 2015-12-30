defmodule Sentry do
  import Sentry.Helpers

  def model do
    verify_phoenix_deps!

    quote do
      def confirmed?(user) do
        if user, do: !!user.confirmed_at
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
