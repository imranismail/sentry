defmodule Sentry.Authorizer do
  import Sentry.Naming, only: [suffix: 2]

  @doc """
  Authorize a resource by running the similarly named function in the similarly named policy module
  """
  def authorized?(conn, changeset, function) do
    module_parts = changeset.model.__struct__ |> Module.split

    policy_module =
      module_parts
      |> List.last()
      |> suffix("Policy")

    module =
      module_parts
      |> List.replace_at(length(module_parts) - 1, policy_module)
      |> Module.concat()

    apply(module, function, [conn, changeset])
  end

  @doc """
  Macro for authorizing resource which will use the lexically scoped module and function name
  """
  defmacro authorize(conn, changeset) do
    quote do
      unless authorized?(unquote(conn), unquote(changeset), elem(__ENV__.function, 0)) do
        raise Sentry.NotAuthorizedError
      end
    end
  end

  defmacro authorize(conn, changeset, function) do
    quote do
      unless authorized?(unquote(conn), unquote(changeset), unquote(function)) do
        raise Sentry.NotAuthorizedError
      end
    end
  end
end
