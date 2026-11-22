defmodule Ctps.Repo do
  use Ecto.Repo,
    otp_app: :ctps,
    adapter: Ecto.Adapters.Postgres
end
