defmodule EctoS3.Path do
  @moduledoc false

  alias EctoS3.ContentType

  # Dealing with a struct (via EctoS3.Adapter.Schema)
  def absolute(schema, fields, format) when is_list(fields) do
    key = key(schema, fields)
    make_path(schema, key, format)
  end

  # Dealing with a single ID (via EctoS3.Adapter.Queryable)
  def absolute(schema, id, format) do
    make_path(schema, id, format)
  end

  defp make_path(schema, key, format) do
    source = schema.__schema__(:source)
    "/" <> Enum.join([source, key], "/") <> ContentType.extension(format)
  end

  defp key(schema, fields) do
    keys = schema.__schema__(:primary_key)
    if keys == [] do
      raise Ecto.NoPrimaryKeyFieldError, schema: schema
    end

    # There may be more than one key if the schema is using a composite primary
    # key.  Concatenate them with dashes.
    Enum.map(keys, fn key ->
      case Keyword.fetch(fields, key) do
        {:ok, val} ->
          val
        :error ->
          raise Ecto.NoPrimaryKeyValueError, struct: schema.__struct__
      end
    end)
    |> Enum.join("-")
  end
end
