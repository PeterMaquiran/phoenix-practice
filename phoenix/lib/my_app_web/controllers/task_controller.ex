defmodule MyAppWeb.TaskController do
  use MyAppWeb, :controller

  alias MyApp.Tasks

  action_fallback MyAppWeb.FallbackController

  def index(conn, _params) do
    render(conn, :index, tasks: Tasks.list_tasks())
  end

  def create(conn, params) do
    with {:ok, task} <- Tasks.create_task(params) do
      conn
      |> put_status(:created)
      |> render(:show, task: task)
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs = Map.delete(params, "id")

    with {:ok, task} <- Tasks.fetch_task(id),
         {:ok, task} <- Tasks.update_task(task, attrs) do
      render(conn, :show, task: task)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, task} <- Tasks.fetch_task(id),
         {:ok, _task} <- Tasks.delete_task(task) do
      send_resp(conn, :no_content, "")
    end
  end
end
