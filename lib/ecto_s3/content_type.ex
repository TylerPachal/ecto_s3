defmodule EctoS3.ContentType do
  @moduledoc false

  def extension(:json) do
    ".json"
  end

  def header(:json) do
    {:content_type, "application/json"}
  end

  def encode(:json, fields) do
    fields
    |> Map.new()
    |> Jason.encode!()
  end

  def decode(:json, body, fields) do
    decoded = Jason.decode!(body)
    Enum.map(fields, fn {field, _type} ->
      Map.get(decoded, to_string(field))
    end)
  end
end
