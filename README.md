# EctoS3

EctoS3 is an Ecto adapter for AWS S3.

Functionally, S3 is a simple object store, with basic read, write, and delete operations.  S3 has no mechanism for bulk operations, complex queries, conflict detection, or streaming.  Thus, many Ecto operations which would normally be popular with a relational database are not supported by EctoS3.

Additionally, many of the "usual" options for the insert and delete functions are not supported.  For example, S3 does not provide a mechanism for conflict detection so the `:on_conflict` option is not supported.

Supported:
- `get`
- `insert`
- `delete`

Unsupported:
- `all`
- `delete_all`
- `insert_all`
- `update_all`
- `get_by` (anything other than the primary key)
- `update`
- `stream`

## Installation

Add the `:ecto_s3` dependency to your `mix.exs` file:

```elixir
def deps do
  [
    {:ecto_s3, "~> 0.0.1"}
  ]
end
```

## Example Usage

Setup a new Ecto Repo with the `EctoS3.Adapter`:

```elixir
defmodule MyApp.Repo do
  use Ecto.Repo,
    adapter: EctoS3.Adapter,
    otp_app: :my_app
end
```

Create an Ecto Schema which represents the contents of your S3 file:

```elixir
defmodule Person do
  use Ecto.Schema
  schema "people" do
    field :name, :string
    field :age, :integer
  end
end
```

```elixir
struct = %Person{id: 1, name: "tyler", age: 100}

# Insert: The resulting file in S3 will be /people/1.json
{:ok, _peson} = Repo.insert(struct)

# Get by ID
person = Repo.get(Person, struct.id)

# Delete
{:ok, _id} = Repo.delete(person)
```

## Testing/Developing

1) Run `docker-compose up` to bring up the external test dependencies

2) Run `MIX_ENV=test mix ecto.create` to create the test Sql database.  This is used for some of the property-based tests.

## TODO

There a list of things I need before I can use this in production.

- Custom paths for schemas.  Having a simple `/person/:id.json` is not sufficient for most of my usecases.  I need to often include extra information in the path including an `:account_id` or `:date`.  There should be a way to express a custom path format so other fields from the schema can be included in the path.

- Migrations.  We should support some sort of migration mechanism that would loop over all S3 files and apply a transformation to the data.  
