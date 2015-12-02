defmodule Sentry.Authorizer do
  import Sentry.Helpers, only: [suffix: 2, unsuffix: 2]

  def authorized_changeset?(conn, changeset, function) do
    module_parts = changeset.model.__struct__ |> Module.split

    policy = module_parts
    |> List.last()
    |> suffix("Policy")

    module_parts
    |> List.replace_at(length(module_parts) - 1, policy)
    |> Module.concat()
    |> apply(function, [conn, changeset])
  end

  def authorized?(conn, module, function, opts) do
    module_parts = module |> Module.split

    policy = module_parts
    |> List.last()
    |> unsuffix("Controller")
    |> suffix("Policy")

    module_parts
    |> List.replace_at(length(module_parts) - 1, policy)
    |> Module.concat()
    |> apply(function, [conn, opts])
  end

  defmacro authorize_changeset(conn, changeset) do
    quote do
      case authorized_changeset?(unquote(conn), unquote(changeset), elem(__ENV__.function, 0)) do
        false  -> raise Sentry.NotAuthorizedError
        result -> result
      end
    end
  end

  defmacro authorize_changeset(conn, changeset, function) do
    quote do
      case authorized_changeset?(unquote(conn), unquote(changeset), unquote(function)) do
        false  -> raise Sentry.NotAuthorizedError
        result -> result
      end
    end
  end

  defmacro authorize(conn, opts \\ nil) do
    quote do
      case authorized?(unquote(conn), __MODULE__, elem(__ENV__.function, 0), unquote(opts)) do
        false  -> raise Sentry.NotAuthorizedError
        result -> result
      end
    end
  end
end
