defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser
    live_dashboard "/dashboard",
      metrics: MyAppWeb.Telemetry,
      ecto_repos: [MyApp.Repo]
  end

  scope "/", MyAppWeb do
    get "/", PageController, :index
    get "/connect2", PageController, :connect2
  end

  scope "/", MyAppWeb do
    pipe_through :api

    get "/posts", PostController, :index
    post "/posts", PostController, :create
    patch "/posts/:id", PostController, :update
    delete "/posts/:id", PostController, :delete

    get "/tasks", TaskController, :index
    post "/tasks", TaskController, :create
    patch "/tasks/:id", TaskController, :update
    delete "/tasks/:id", TaskController, :delete
  end
end
