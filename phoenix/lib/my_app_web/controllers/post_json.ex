defmodule MyAppWeb.PostJSON do
  def index(%{posts: posts}) do
    %{data: Enum.map(posts, &data/1)}
  end

  def show(%{post: post}) do
    %{data: data(post)}
  end

  def data(post) do
    %{
      id: post.id,
      title: post.title,
      body: post.body
    }
  end
end
