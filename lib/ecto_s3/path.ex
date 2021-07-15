defmodule EctoS3.Path do
  @moduledoc false

  alias EctoS3.ContentType

  # The prefix can be a list, or a single value.  Normalize the input to a list.
  def absolute(schema, fields, format, prefix) when not is_list(prefix) do
    prefix = List.wrap(prefix)
    absolute(schema, fields, format, prefix)
  end

  # Dealing with a struct (via EctoS3.Adapter.Schema)
  def absolute(schema, fields, format, prefix) when is_list(fields) do
    key = key(schema, fields)
    make_path(schema, key, format, prefix)
  end

  # Dealing with a single ID (via EctoS3.Adapter.Queryable)
  def absolute(schema, id, format, prefix) do
    make_path(schema, id, format, prefix)
  end

  defp make_path(schema, key, format, prefix) do
    source = schema.__schema__(:source)
    elements = prefix ++ [source, key]
    "/" <> Enum.join(elements, "/") <> ContentType.extension(format)
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
