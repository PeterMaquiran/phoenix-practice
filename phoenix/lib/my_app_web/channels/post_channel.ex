defmodule MyAppWeb.PostChannel do
  use MyAppWeb, :channel

  alias MyApp.Posts
  alias MyAppWeb.PostJSON

  @impl true
  def join("posts", _payload, socket) do
    {:ok, %{data: Enum.map(Posts.list_posts(), &PostJSON.data/1)}, socket}
  end

  @impl true
  def handle_in("list", _payload, socket) do
    {:reply, {:ok, %{data: Enum.map(Posts.list_posts(), &PostJSON.data/1)}}, socket}
  end

  def handle_in("create", payload, socket) do
    case Posts.create_post(payload) do
      {:ok, post} ->
        payload = PostJSON.data(post)
        broadcast_from!(socket, "created", payload)
        {:reply, {:ok, payload}, socket}

      {:error, changeset} ->
        {:reply, {:error, error(changeset)}, socket}
    end
  end

  def handle_in("update", %{"id" => id} = payload, socket) do
    attrs = Map.delete(payload, "id")

    with {:ok, post} <- Posts.fetch_post(id),
         {:ok, post} <- Posts.update_post(post, attrs) do
      payload = PostJSON.data(post)
      broadcast_from!(socket, "updated", payload)
      {:reply, {:ok, payload}, socket}
    else
      {:error, reason} ->
        {:reply, {:error, error(reason)}, socket}
    end
  end

  def handle_in("delete", %{"id" => id}, socket) do
    with {:ok, post} <- Posts.fetch_post(id),
         {:ok, post} <- Posts.delete_post(post) do
      payload = PostJSON.data(post)
      broadcast_from!(socket, "deleted", payload)
      {:reply, {:ok, payload}, socket}
    else
      {:error, reason} ->
        {:reply, {:error, error(reason)}, socket}
    end
  end

  def handle_in(event, _payload, socket) when event in ["update", "delete"] do
    {:reply, {:error, %{error: "id is required"}}, socket}
  end

  defp error(:not_found), do: %{error: "not found"}

  defp error(%Ecto.Changeset{} = changeset) do
    MyAppWeb.ChangesetJSON.error(%{changeset: changeset})
  end
end
