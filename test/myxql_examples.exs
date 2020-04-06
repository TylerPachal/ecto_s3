defmodule MyXQLExamples do
  @moduledoc """
  The purpose of this files is just to collect all of the functionality of the
  MyXQL adapter, which we are using to model behaviour for EctoS3.

  EctoS3 will not be able to support all options/functions because S3 has
  limited functionality compared to a relational database.
  """
  use ExUnit.Case, async: false
  import S3Helpers
  alias EctoS3.Support.{SqlRepo, S3Repo}

  setup_all do
    {:ok, _pid} = S3Repo.start_link()
    {:ok, _pid} = SqlRepo.start_link()
    :ok
  end

  setup do
    # Clean S3 buckets between tests
    reset_buckets()

    # Clean database between tests
    Ecto.Adapters.SQL.query!(SqlRepo, "DROP TABLE IF EXISTS people")
    Ecto.Adapters.SQL.query!(SqlRepo, "CREATE TABLE people (id VARCHAR(100) primary key, name VARCHAR(100), age integer)")

    :ok
  end

  defmodule Person do
    use Ecto.Schema
    @primary_key {:id, :binary_id, autogenerate: true}
    schema "people" do
      field :name, :string
      field :age, :integer
    end
  end

  # https://hexdocs.pm/ecto/Ecto.Repo.html#c:insert/2-options
  describe "insert/2" do
    test ":returning - true" do
      options = [returning: true]
      struct = %Person{name: "tyler", age: 100}

      assert_raise(
        ArgumentError,
        "MySQL does not support :read_after_writes in schemas for non-primary keys. The following fields in ProtocolTest.Person are tagged as such: [:age, :name, :id]",
        fn ->
          SqlRepo.insert(struct, options)
        end
      )
    end

    test ":returning - false" do
      options = [returning: false]
      struct = %Person{name: "tyler", age: 100}

      assert {:ok, %Person{id: id, name: "tyler", age: 100}} = SqlRepo.insert(struct, options)
      assert id != nil

      assert {:ok, %Person{id: id, name: "tyler", age: 100}} = S3Repo.insert(struct, options)
      assert id != nil
    end

    test ":returning - list of fields" do

    end

    test ":prefix" do

    end

    test ":on_conflict - default (:raise)" do
      options = []


    end

    test ":on_conflict - :raise" do

    end

    test ":on_conflict - :nothing" do

    end

    test ":on_conflict - :replace_all" do

    end

    test ":on_conflict - {:replace_all_except, fields}" do

    end

    test ":on_conflict - {:replace, fields}" do

    end

    test ":on_conflict - keyword list of instructions" do

    end

    test ":on_conflict - Ecto.Query" do

    end

    test ":conflict_target" do

    end

    test ":stale_error_field" do

    end

    test ":stale_error_message" do

    end
  end

end