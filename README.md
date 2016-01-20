[![Build Status](https://semaphoreci.com/api/v1/projects/2872cf3c-d94e-4adb-be74-5f08e95103be/668414/badge.svg)](https://semaphoreci.com/ruby2elixir/sentry)
[![Hex version](https://img.shields.io/hexpm/v/sentry.svg "Hex version")](https://hex.pm/packages/sentry)
![Hex downloads](https://img.shields.io/hexpm/dt/sentry.svg "Hex downloads")


# Sentry

"Sentry provides a set of helpers and conventions that will guide you in leveraging Elixir modules to build a simple, robust authorization system." - Inspired by [elabs/pundit](https://github.com/elabs/pundit)

**This code is still a proof of concept** as it is. I am making sure that once it nears 1.0 I'll make sure things are in order and stabilized, for now setting up authorization with Plug is fairly easy, I'm thinking of ways to make it even easier by utilizing the private fields in phoenix conn struct.

## TODOs
- Generators

## Installation
Add sentry to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:sentry, "~> 0.3"}]
end
```

## License

Sentry is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)

