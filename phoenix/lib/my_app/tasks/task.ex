defmodule MyApp.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :title, :string
    field :done, :boolean, default: false
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :done])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 200)
  end
end
