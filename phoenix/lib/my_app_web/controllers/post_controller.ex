defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller

  alias MyApp.Posts

  action_fallback MyAppWeb.FallbackController

  def index(conn, _params) do
    render(conn, :index, posts: Posts.list_posts())
  end

  def create(conn, params) do
    with {:ok, post} <- Posts.create_post(params) do
      conn
      |> put_status(:created)
      |> render(:show, post: post)
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs = Map.delete(params, "id")

    with {:ok, post} <- Posts.fetch_post(id),
         {:ok, post} <- Posts.update_post(post, attrs) do
      render(conn, :show, post: post)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, post} <- Posts.fetch_post(id),
         {:ok, _post} <- Posts.delete_post(post) do
      send_resp(conn, :no_content, "")
    end
  end
end
