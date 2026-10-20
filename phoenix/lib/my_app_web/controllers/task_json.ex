defmodule MyAppWeb.TaskJSON do
  def index(%{tasks: tasks}) do
    %{data: Enum.map(tasks, &data/1)}
  end

  def show(%{task: task}) do
    %{data: data(task)}
  end

  def data(task) do
    %{
      id: task.id,
      title: task.title,
      done: task.done
    }
  end
end
