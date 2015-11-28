defmodule Sentry do
  import Sentry.Naming

  defmacro __using__(_opts) do
    quote do
      import Sentry
    end
  end

  @doc """
  Authorize a resource by running the similarly named function in the similarly named policy module
  """
  def authorize(conn, resource, function) do
    module_parts = resource.__struct__ |> Module.split

    policy_module =
      module_parts
      |> List.last()
      |> suffix("Policy")

    module =
      module_parts
      |> List.replace_at(length(module_parts) - 1, policy_module)
      |> Module.concat()

    apply(module, function, [conn, resource])
  end

  @doc """
  Macro for authorizing resource which will use the lexically scoped module and function name
  """
  defmacro authorize(conn, resource) do
    quote do
      {function, _arity} = __ENV__.function
      authorize(unquote(conn), unquote(resource), function)
    end
  end
end
