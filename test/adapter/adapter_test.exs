defmodule EctoS3.AdapterTest do
  use ExUnit.Case, async: false
  import S3Helpers
  alias EctoS3.Support.{SqlRepo, S3Repo}

  setup_all do
    {:ok, _pid} = S3Repo.start_link()
    :ok
  end

  setup do
    reset_buckets()
    :ok
  end

  defmodule Person do
    use Ecto.Schema
    @primary_key {:id, :integer, autogenerate: false}
    schema "people" do
      field :name, :string
      field :age, :integer
    end
  end

  describe "update" do
    test "raises error" do
      changeset =
        %Person{id: 9}
        |> Ecto.Changeset.cast(%{"name" => "tyler", "age" => 100}, [:id, :name])

      assert_raise EctoS3.UnsupportedOperationError, ~r(S3Repo.update/2 is not supported), fn ->
        S3Repo.update(changeset)
      end
    end
  end

  describe "insert_all" do
    test "raises error" do
      assert_raise EctoS3.UnsupportedOperationError, ~r(S3Repo.insert_all/3 is not supported), fn ->
        S3Repo.insert_all(Person, [[name: "foo", age: 0]])
      end
    end
  end

  describe "insert" do
    test "uses the schema name for the folder name and the id for the file name" do
      struct = %Person{id: 1, name: "tyler", age: 100}
      S3Repo.insert(struct)
      assert_s3_exists "/people/1.json"
    end

    defmodule Schema_01 do
      use Ecto.Schema
      @primary_key {:custom_id, :string, []}
      schema "schema_01_name" do end
    end

    test "uses the @primary_key module attribute for the file name" do
      struct = %Schema_01{custom_id: "123"}
      assert {:ok, %{custom_id: "123"}} = S3Repo.insert(struct)
      assert_s3_exists "/schema_01_name/123.json"
    end

    defmodule Schema_02 do
      use Ecto.Schema
      @primary_key false
      schema "schema_02_name" do
        field :custom_id, :string, primary_key: true
      end
    end

    test "uses the primary_key: true field config for the file name" do
      struct = %Schema_02{custom_id: "456"}
      assert {:ok, %{custom_id: "456"}} = S3Repo.insert(struct)
      assert_s3_exists "/schema_02_name/456.json"
    end

    test "raises an error if the primary key field's value was not set" do
      struct = %Schema_02{}
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        S3Repo.insert(struct)
      end
    end

    defmodule Schema_03 do
      use Ecto.Schema
      @primary_key false
      schema "schema_03_name" do
        field :part_1, :string, primary_key: true
        field :part_2, :string, primary_key: true
      end
    end

    test "uses the composite primary key for the file name" do
      struct = %Schema_03{part_1: "p1", part_2: "p2"}
      assert {:ok, _} = S3Repo.insert(struct)
      assert_s3_exists "/schema_03_name/p1-p2.json"
    end

    test "raises an error if either of the primary key fields' value were not set" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        S3Repo.insert(%Schema_03{})
      end

      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        S3Repo.insert(%Schema_03{part_1: "p1"})
      end

      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        S3Repo.insert(%Schema_03{part_2: "p2"})
      end
    end

    defmodule Schema_04 do
      use Ecto.Schema
      @primary_key {:custom_id, :binary_id, autogenerate: true}
      schema "schema_04_name" do end
    end

    test "autogenerates a key when required" do
      struct = %Schema_04{}
      assert {:ok, %{custom_id: id}} = S3Repo.insert(struct)
      assert_s3_exists "/schema_04_name/#{id}.json"
    end

    test "does not autogenerate a key when a value is already present" do
      id = Ecto.UUID.generate()
      struct = %Schema_04{custom_id: id}
      assert {:ok, %{custom_id: ^id}} = S3Repo.insert(struct)
      assert_s3_exists "/schema_04_name/#{id}.json"
    end

    test "does not insert invalid changeset" do
      changeset =
        %Person{id: 10}
        |> Ecto.Changeset.cast(%{"age" => 100}, [:id, :name])
        |> Ecto.Changeset.validate_required(:name)

      assert {:error, changeset} = S3Repo.insert(changeset)
      assert changeset.valid? == false
    end

    defmodule Schema_05 do
      use Ecto.Schema
      @primary_key false
      schema "schema_05_name" do
        field :foo, :string
      end
    end

    test "raises NoPrimaryKeyFieldError if the schema has no primary key field" do
      struct = %Schema_05{foo: "bar"}
      assert_raise Ecto.NoPrimaryKeyFieldError, fn ->
        S3Repo.insert(struct)
      end
    end
  end
end
