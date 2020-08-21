defmodule EctoS3.AdapterTest do
  use ExUnit.Case, async: false
  import S3Helpers
  alias EctoS3.Support.S3Repo

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

  describe "delete_all" do
    test "raises error" do
      assert_raise EctoS3.UnsupportedOperationError, fn ->
        S3Repo.delete_all(Person)
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

    test "raises error when :on_conflict option is set to something other than the default of :raise or :nothing (even though we ignore any value)" do
      # Doesn't raise an error in this case
      S3Repo.insert(%Person{id: 9}, on_conflict: :nothing)

      assert_raise EctoS3.UnsupportedOperationError, ~r(allows the :nothing value), fn ->
        S3Repo.insert(%Person{id: 9}, on_conflict: :replace_all)
      end

      assert_raise EctoS3.UnsupportedOperationError, fn ->
        S3Repo.insert(%Person{id: 9}, on_conflict: {:replace_all_except, [:id, :name]})
      end
    end

    test "raises error when :stale_error_field is set" do
      assert_raise EctoS3.UnsupportedOperationError, ~r(not support the :stale_error_field option), fn ->
        S3Repo.insert(%Person{id: 800}, stale_error_field: :name)
      end
    end
  end

  describe "delete" do
    setup do
      struct = %Person{id: 900, name: "tyler", age: 0}
      S3Repo.insert!(struct)

      [struct: struct]
    end

    test "delete using struct", %{struct: struct} do
      assert {:ok, id} = S3Repo.delete(struct)
      assert_s3_not_exists "/people/900.json"
    end

    test "delete using changeset", %{struct: struct} do
      changeset = Ecto.Changeset.change(struct)
      assert {:ok, id} = S3Repo.delete(changeset)
      assert_s3_not_exists "/people/900.json"
    end

    test "deleting something which has no primary key value raises an error" do
      struct = %Person{name: "tyler", age: 0}
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        S3Repo.delete(struct)
      end
    end
  end

  describe "get" do
    test "retrieves by ID" do
      struct = %Person{id: 444, name: "tyler", age: nil}
      payload = Poison.encode!(struct)
      write_s3_file("/people/444.json", payload)

      assert struct == S3Repo.get(Person, 444)
    end
  end

  describe "get_by" do
  end
end
