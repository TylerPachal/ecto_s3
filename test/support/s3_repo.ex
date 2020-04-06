defmodule EctoS3.Support.S3Repo do
  use Ecto.Repo,
    adapter: EctoS3.Adapter,
    otp_app: :ecto_s3
end
