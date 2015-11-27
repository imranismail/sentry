defmodule Sentry do
  import Phoenix.Naming, only: [unsuffix: 2]
  import Sentry.Naming, only: [suffix: 2]

  defmacro __using__(_opts) do
    quote do
      import Sentry, only: [authorize_resource: 3, authorize: 1, authorize: 2, authorize: 3]
    end
  end

  @doc """
  Authorize a resource by running the similarly named function in the similarly named policy module
  """
  def authorize_resource(resource, module, function) do
    module_tree = module |> Module.split()

    policy_module =
      module_tree
      |> List.last()
      |> unsuffix("Controller")
      |> suffix("Policy")

    module =
      module_tree
      |> List.replace_at(length(module_tree) - 1, policy_module)
      |> Module.concat()

    {policy_function, _} = function

    apply(module, policy_function, [resource])
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
