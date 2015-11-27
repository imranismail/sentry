defmodule Sentry do
  import Phoenix.Naming, only: [unsuffix: 2]
  import Sentry.Naming, only: [suffix: 2]

  defmacro __using__(_opts) do
    quote do
      import Sentry, only: [authorize_resource: 3, authorize: 1, authorize: 2, authorize: 3]
    end
  end

  @doc """
  Authorize a resource by running the similarly named function in the policy module
  """
  def authorize_resource(resource, module, function) do
    module
    |> to_string()
    |> Module.split()
    |> List.last()
    |> unsuffix("Controller")
    |> suffix("Policy")
    |> Code.eval_string()
    |> elem(0)
    |> apply(elem(function, 0), [resource])
  end

  @doc """
  Macro for authorizing resource which will use the module and function name
  """
  defmacro authorize(user) do
    quote do
      authorize_resource(unquote(user), __ENV__.module, __ENV__.function)
    end
  end

  defmacro authorize(user, function) do
    quote do
      authorize_resource(unquote(user), __ENV__.module, unquote(function))
    end
  end

  defmacro authorize(user, module, function) do
    quote do
      authorize_resource(unquote(user), unquote(module), unquote(function))
    end
  end
end
