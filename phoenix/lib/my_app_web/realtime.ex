defmodule MyAppWeb.Realtime do
  alias MyAppWeb.Endpoint

  def broadcast_post!(event, post) do
    payload = MyAppWeb.PostJSON.data(post)
    Endpoint.broadcast!("posts", event, payload)
    payload
  end

  def broadcast_task!(event, task) do
    payload = MyAppWeb.TaskJSON.data(task)
    Endpoint.broadcast!("tasks", event, payload)
    payload
  end
end
