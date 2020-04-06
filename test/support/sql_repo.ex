defmodule EctoS3.Support.SqlRepo do
  use Ecto.Repo,
    adapter: Ecto.Adapters.MyXQL,
    otp_app: :ecto_s3
end
