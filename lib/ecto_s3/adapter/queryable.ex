defmodule EctoS3.Adapter.Queryable do
  @moduledoc false

  @behaviour Ecto.Adapter.Queryable

  alias EctoS3.{ContentType, Path, UnsupportedOperationError}

  @impl true
  def prepare(:all, query) do
    {:nocache, query}
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
  def execute(adapter_meta, %{select: %{from: from}}, {:nocache, query}, [id], _options) do
    %{bucket: bucket, format: format, repo: repo} = adapter_meta
    {:any, {:source, {_source, schema_module}, nil, fields}} = from

    path = Path.absolute(schema_module, id, format)
    request = ExAws.S3.get_object(bucket, path)

    case ExAws.request(request)  do
      {:ok, %{body: body}} ->
        {1, [ContentType.decode(format, body, fields)]}
      {:error, {:http_error, 404, _body}} ->
        {0, []}
    end
  end

  def execute(_adapter_meta, _query_meta, _query_cache, _params, _options) do
    raise UnsupportedOperationError, message: """
      EctoS3 does not support Ecto's Queryable operations

      S3 has basic read, write, and delete operations, but no way to construct
      complex queries.

      Because of this the only query operation that is supported is the
      MyRepo.get/2 function, which fetches by the primary key:

        MyRepo.get(MyModule, id)
      """
  end

  @impl true
  def stream(_adapter_meta, _query_meta, _query_cache, _params, _options) do
    raise UnsupportedOperationError, message: """
    EctoS3 does not support Ecto's Stream operations
    """
  end
end
