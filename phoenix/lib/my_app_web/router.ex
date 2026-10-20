defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MyAppWeb do
    get "/", PageController, :index
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
