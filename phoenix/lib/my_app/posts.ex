defmodule MyApp.Posts do
  import Ecto.Query
  alias MyApp.Posts.Post
  alias MyApp.Repo

  def list_posts do
    Repo.all(from p in Post, order_by: [asc: p.id])
  end

  def fetch_post(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} -> fetch_post(int)
      _ -> {:error, :not_found}
    end
  end

  def fetch_post(id) when is_integer(id) do
    case Repo.get(Post, id) do
      nil -> {:error, :not_found}
      post -> {:ok, post}
    end
  end

  def create_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end
end
