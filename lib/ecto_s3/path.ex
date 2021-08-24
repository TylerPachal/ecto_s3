defmodule EctoS3.Path do
  @moduledoc false

  alias EctoS3.ContentType

  def construct(_schema, fields, _format, path_format) when is_binary(path_format) do
    custom(path_format, fields)
  end
  def construct(schema, fields, format, _path_format) do
    absolute(schema, fields, format)
  end

  # Dealing with a struct (via EctoS3.Adapter.Schema)
  def absolute(schema, fields, format) when is_list(fields) do
    key = key(schema, fields)
    absolute(schema, key, format)
  end

  # Dealing with a single ID (via EctoS3.Adapter.Queryable)
  def absolute(schema, key, format) do
    source = schema.__schema__(:source)
    elements = [source, key]
    "/" <> Enum.join(elements, "/") <> ContentType.extension(format)
  end

  def custom(path_format, fields) do
    # Loop over all of the fields and see if any of them are in the path, if they
    # are, replace them with the corresponding value.
    Enum.reduce(fields, path_format, fn {key, val}, acc ->
      String.replace(acc, ":#{key}", to_string(val))
    end)
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
