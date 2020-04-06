defmodule EctoS3.Adapter do
  @moduledoc """
  Used as an Adapter in Repo modueles, which uses an S3 bucket as the
  "database" and one folder per schema.  Each file will be named based on the
  value of the primary key of the schema.

  S3 does not support bulk writes, updating, or querying, so the only
  operations that are supported by EctoS3 are insert/get/delete for single
  resources

  To use EctoS3 in your application, define a repo like the following:

      defmodule MyApp.Repo do
        use Ecto.Repo,
          adapter: EctoS3.Adapter,
          otp_app: :my_app
      end

  """

  require Logger

  @behaviour Ecto.Adapter

  @impl true
  def __before_compile__(_env) do
    :ok
  end

  @impl true
  def checkout(_adapter_meta, _config, function) do
    function.()
  end

  @impl true
  def dumpers(_, type), do: [type]

  @impl true
  def loaders(_, type), do: [type]

  @impl true
  def ensure_all_started(_config, _type) do
    Application.ensure_all_started(:aws_s3)
  end

  @impl true
  def init(config) do
    # This config is what comes from the s3_repo.ex when you `use Ecto.Repo`
    # and gets merged with whatever is in the config under
    # `config :ecto_s3, S3Repo`
    bucket = config[:bucket]
    repo = config[:repo]
    format = config[:format] || :json

    if !is_binary(bucket) do
      raise "A config value is required for :bucket"
    end

    supported_formats = [:json]
    if !Enum.member?(supported_formats, format) do
      raise "The value for :format must be one of: #{inspect supported_formats}"
    end

    adapter_meta = %{
      bucket: bucket,
      repo: repo,
      format: format,
    }

    {:ok, EctoS3.Supervisor.child_spec(), adapter_meta}
  end


  ## ----- Ecto.Adapter.Schema -----
  @behaviour Ecto.Adapter.Schema

  @impl Ecto.Adapter.Schema
  defdelegate autogenerate(field_type), to: EctoS3.Adapter.Schema

  @impl Ecto.Adapter.Schema
  defdelegate insert_all(adapter_meta, schema_meta, header, list, on_conflict, returning, options), to: EctoS3.Adapter.Schema

  @impl Ecto.Adapter.Schema
  defdelegate insert(adapter_meta, schema_meta, fields, on_conflict, returning, options), to: EctoS3.Adapter.Schema

  @impl Ecto.Adapter.Schema
  defdelegate update(adapter_meta, schema_meta, fields, filters, returning, options), to: EctoS3.Adapter.Schema

  @impl Ecto.Adapter.Schema
  defdelegate delete(adapter_meta, schema_meta, filters, options), to: EctoS3.Adapter.Schema


  ## ----- Ecto.Adapter.Queryable -----
  # @behaviour Ecto.Adapter.Queryable
end
