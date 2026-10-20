defmodule MyApp.Tasks do
  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Tasks.Task

  def list_tasks do
    Repo.all(from t in Task, order_by: [asc: t.id])
  end

  def fetch_task(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} -> fetch_task(int)
      _ -> {:error, :not_found}
    end
  end

  def fetch_task(id) when is_integer(id) do
    case Repo.get(Task, id) do
      nil -> {:error, :not_found}
      task -> {:ok, task}
    end
  end

  def create_task(attrs) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end
end
