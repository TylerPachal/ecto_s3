ExUnit.start()

defmodule S3Helpers do

  def reset_buckets() do
    buckets = ["s3_ecto_test", "s3_ecto_test_2"]

    Enum.each(buckets, fn bucket ->
      ExAws.S3.delete_bucket(bucket) |> ExAws.request()
      ExAws.S3.put_bucket(bucket, "us-west-2") |> ExAws.request()
    end)
  end

  defmacro assert_s3_exists(path, options \\ []) do
    bucket = Keyword.get(options, :bucket) || "s3_ecto_test"

    quote do
      case ExAws.S3.get_object(unquote(bucket), unquote(path)) |> ExAws.request() do
        {:error, {:http_error, 404, _}} ->
          flunk("#{unquote(path)} does not exist in #{unquote(bucket)}")

        {:ok, %{status_code: 200}} ->
          assert true
      end
    end
  end
end
