defmodule EctoS3.Adapter.Queryable do
  @behaviour Ecto.Adapter.Queryable

  alias EctoS3.UnsupportedOperationError

  @impl true
  def prepare(:all, query) do
    {:nocache, query}
  end

  def prepare(:all, %Ecto.Query{from: %{source: {_source_schema, source_module}}} = q) do
    module = Module.split(source_module) |> List.last()

    IO.inspect(q, structs: false)

    # raise UnsupportedOperationError, message: """
    #   MyRepo.all(#{module}) is not supported.

    #   S3 has basic read, write, and delete operations, but no bulk get
    #   operation.  Because of this the MyRepo.all/2 function is not implemented
    #   and should be replaced by multiple calls to MyRepo.get/3:

    #     Enum.map(ids, &MyRepo.get(#{module}, &1))
    #   """
  end

  @impl true
  def prepare(:delete_all, %Ecto.Query{from: %{source: {_source_schema, source_module}}}) do
    module = Module.split(source_module) |> List.last()

    raise UnsupportedOperationError, message: """
      MyRepo.delete_all(#{module}) is not supported.

      S3 has basic read, write, and delete operations, but no bulk delete
      operation.  Because of this the MyRepo.delete_all/2 function is not
      implemented and should be replaced by multiple calls to MyRepo.delete/2:

        Enum.map(values, &MyRepo.delete/2)
      """
  end

  @impl true
  def prepare(:update_all, %Ecto.Query{from: %{source: {_source_schema, source_module}}}) do
    module = Module.split(source_module) |> List.last()

    raise UnsupportedOperationError, message: """
      MyRepo.update_all(#{module}) is not supported.

      S3 has basic read, write, and delete operations, but doesn't support bulk
      updates or basic update operations.  Because of this the
      MyRepo.update_all/2 function is not implemented and should be replaced by
      multiple calls using a combination of MyRepo.get/3 and MyRepo.insert/2:

        Enum.map(values, fn value ->
          exising_value = MyRepo.get(#{module}, value.id)
          updated_value = ...
          MyRepo.insert(update_value)
        end)
      """
  end

  @impl true
  def execute(adapter_meta, %{select: %{from: from}}, {:nocache, _query}, [id], _options) do
    %{bucket: bucket, format: format, repo: repo} = adapter_meta
    {:any, {:source, {source, schema_module}, nil, [id: :integer, name: :string, age: :integer]}} = from

    # TODO: Inspect the schema to handle composite keys and stuff
    # TODO: Use the format from the adapter_meta for the extension
    extension = ".json"
    path = "/" <> Enum.join([source, id], "/") <> extension

    # TODO: Use format here for decoding
    # TODO: Handle error cases
    case ExAws.S3.get_object(bucket, path) |> ExAws.request()  do
      {:ok, %{body: body}} ->
        # TODO: Do this conversion
        Poison.decode!(body)
        {1, [[444, "tyler", nil]]}
    end
  end

  def execute(_adapter_meta, _query_meta, _query_cache, _params, _options) do
    raise UnsupportedOperationError, message: """
    EctoS3 does not support Ecto's Queryable operations.
    """
  end

  @impl true
  def stream(_adapter_meta, _query_meta, _query_cache, _params, _options) do
    raise UnsupportedOperationError, message: """
    EctoS3 does not support Ecto's Queryable operations.
    """
  end
end
