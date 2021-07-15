# Don't change this module!  There are test that depend on it being the way it is (mostly the
# primary key).
defmodule EctoS3.Support.Person do
  use Ecto.Schema
  @primary_key {:id, :integer, autogenerate: false}
  @derive {Jason.Encoder, except: [:__meta__]}
  schema "people" do
    field :name, :string
    field :age, :integer
  end
end
