defmodule MyAppWeb.PageController do
  use MyAppWeb, :controller

  def index(conn, _params), do: send_page(conn, "index.html")
  def connect2(conn, _params), do: send_page(conn, "connect2.html")

  defp send_page(conn, name) do
    path = Application.app_dir(:my_app, "priv/static/#{name}")

    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, path)
  end
end
