ExUnit.start()

Mix.Task.run "ecto.create", ["--quiet"]
Mix.Task.run "ecto.migrate", ["--quiet"]
Sentry.Repo.start_link
Ecto.Adapters.SQL.begin_test_transaction(Sentry.Repo)
