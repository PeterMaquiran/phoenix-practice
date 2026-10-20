defmodule MyAppWeb.PageController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    path = Application.app_dir(:my_app, "priv/static/index.html")

    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, path)
  end
end
