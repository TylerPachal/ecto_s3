import Config

alias EctoS3.Support.{SqlRepo, S3Repo}

config :ecto_s3, ecto_repos: [SqlRepo]

config :ecto_s3, S3Repo,
  bucket: "s3_ecto_test"

config :ecto_s3, SqlRepo,
  database: "ecto_s3_test",
  username: "root",
  password: "",
  hostname: "127.0.0.1"

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9090,

  # These need to be here or our AWS library will complain, but since we are
  # using adobe/s3mock their values don't matter
  access_key_id: "",
  secret_access_key: "",
  region: ""
