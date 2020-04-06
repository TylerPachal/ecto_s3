defmodule EctoS3.Supervisor do
  use Supervisor
  require Logger

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  def start_link() do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end
end
