defmodule EctoS3.Adapter do
  @moduledoc """
  EctoS3.Adapater is used in application Repo modules.

  An S3 bucket is used at the "database" and folders are used for schemas.
  Each file will be named based on the value of the primary key of the schema.

  S3 has basic read, write, and delete operations, but has no mechanism for
  bulk operations, complex queries, conflict detection, or streaming.  Thus,
  EctoS3 only supports read, write, and delete operations on single resources.

  Additionally, many of the "usual" options for the insert and delete functions
  are not supported.  For example, S3 does not provide a mechanism for conflict
  detection so the `:on_conflict` option is not supported.

  To use EctoS3 in your application, define a repo like the following:

      defmodule MyApp.Repo do
        use Ecto.Repo,
          adapter: EctoS3.Adapter,
          otp_app: :my_app
      end

  Then assuming you have a schema something like this:

      defmodule Person do
        use Ecto.Schema
        schema "people" do
          field :name, :string
          field :age, :integer
        end
      end

  You can use the Repo to perform operations like this:

      struct = %Person{id: 1, name: "tyler", age: 100}

      # Insert: The resulting file in S3 will be /people/1.json
      {:ok, _peson} = Repo.insert(struct)

      # Get by ID
      person = Repo.get(Person, struct.id)

      # Delete
      {:ok, _id} = Repo.delete(person)
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
  def checked_out?(_adapter_meta) do
    false
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
  defdelegate insert_all(adapter_meta, schema_meta, header, list, on_conflict, returning, placeholders, options), to: EctoS3.Adapter.Schema

  @impl Ecto.Adapter.Schema
  defdelegate insert(adapter_meta, schema_meta, fields, on_conflict, returning, options), to: EctoS3.Adapter.Schema

  @impl Ecto.Adapter.Schema
  defdelegate update(adapter_meta, schema_meta, fields, filters, returning, options), to: EctoS3.Adapter.Schema

  @impl Ecto.Adapter.Schema
  defdelegate delete(adapter_meta, schema_meta, filters, options), to: EctoS3.Adapter.Schema


  ## ----- Ecto.Adapter.Queryable -----
  @behaviour Ecto.Adapter.Queryable

  @impl Ecto.Adapter.Queryable
  defdelegate prepare(atom, query), to: EctoS3.Adapter.Queryable

  @impl Ecto.Adapter.Queryable
  defdelegate execute(adapter_meta, query_meta, query_cache, params, options), to: EctoS3.Adapter.Queryable

  @impl Ecto.Adapter.Queryable
  defdelegate stream(adapter_meta, query_meta, query_cache, params, options), to: EctoS3.Adapter.Queryable
end
