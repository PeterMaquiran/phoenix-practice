# From NestJS to Phoenix

A practical map for people who already know NestJS and want Phoenix to feel familiar fast, without pretending Elixir is TypeScript with different syntax.

Read this once for the landscape, then build the small feature in [A feature, translated](#a-feature-translated). The mapping sticks when you type it.

---

## Is this a good way to learn?

Yes, with one rule.

NestJS and Phoenix solve the same product problems: HTTP in, validation, auth, persistence, background work, realtime out. You already know those problems. Using Nest as a landmark is faster than learning Phoenix as if you had never built a backend.

It becomes a bad way to learn the moment you try to recreate Nest inside Elixir: a DI container, classes, decorators, mutable services, `this`. Those are Nest's tools. Phoenix's tools are functions, pipelines, pattern matching, and processes. The tutorial below translates the *job*, then shows the Phoenix way of doing that job.

If a section says the analogy stops, believe that section more than the table.

---

## The one mental shift

| NestJS | Phoenix |
| --- | --- |
| Objects hold state and behavior | Data is plain maps and structs. Functions transform them |
| The framework calls your classes | You pass a `conn` (or a socket) through a pipeline of functions |
| A module wires providers together | A context is the public API of a business area. Call it like a module of functions |
| Invalid states become exceptions | Invalid states become `{:error, reason}` tuples you pattern-match |
| Long-lived state lives on a class instance | Long-lived state lives in a process, supervised by the OTP tree |

You will feel the urge to "inject" a service. In Phoenix you call `MyApp.Blog.create_post(attrs)`. If the implementation must be swappable (mailer, payments), you use a behaviour plus config, not a container.

---

## Map at a glance

| You know this in Nest | Closest thing in Phoenix | How close? |
| --- | --- | --- |
| `AppModule` / feature `@Module()` | Context module (`MyApp.Blog`) plus a web boundary (`MyAppWeb`) | Loose. No imports/providers/exports array |
| `@Controller()` + `@Get()` | `router.ex` route + controller action | Close |
| `@Injectable()` service | Functions on a context module | Close in role, different mechanism |
| Constructor injection | Function arguments, or `Application.get_env/2` for a swappable impl | Different |
| DTO + `class-validator` | Ecto changeset | Close in role |
| `ValidationPipe` | Changeset, sometimes a plug | Loose |
| Middleware | Plug | Very close |
| Guard | Plug that `halt`s, or a router pipeline | Close |
| Interceptor | Plug around the action, or a controller plug | Loose |
| Exception filter | `action_fallback` + `ErrorJSON` | Close |
| TypeORM / Prisma entity | Ecto schema | Close |
| Repository | `MyApp.Repo` + query functions in the context | Close |
| ConfigModule + `.env` | `config/*.exs` and `runtime.exs` | Close |
| Passport / JWT guard | `phx.gen.auth` plugs, or a token plug you write | Close in role |
| `@WebSocketGateway()` | Channel + `Phoenix.PubSub` | Phoenix is stronger here |
| `@Cron()` / Bull | Oban, or a `GenServer` | Close in role |
| Jest + `@nestjs/testing` | ExUnit + `ConnCase` / `DataCase` | Close |
| React SPA talking to your API | LiveView, when the UI is server-rendered and realtime | No Nest equivalent |

---

## How a Phoenix app is split

`mix phx.new my_app` gives you two applications in one project:

```text
lib/
  my_app/                 # business layer: contexts, schemas, workers
    application.ex        # OTP supervision tree (the process root)
    repo.ex
    blog.ex               # context: the API other code is allowed to call
    blog/
      post.ex             # schema + changeset
  my_app_web/             # delivery layer: HTTP, sockets, HTML
    router.ex
    controllers/
    channels/
    live/
    components/
config/
  config.exs              # compile-time config
  dev.exs
  test.exs
  runtime.exs             # secrets and prod config, read at boot
test/
```

Nest puts a feature's controller, service, entity, and module in one folder (`posts/`). Phoenix splits by *layer*: business rules live in `lib/my_app`, HTTP lives in `lib/my_app_web`. A controller may call `MyApp.Blog`. `MyApp.Blog` does not know controllers exist.

**Where the analogy stops.** A Nest module both organizes files and builds the DI graph. A Phoenix context only organizes the public functions of one business area. The supervision tree in `application.ex` is the thing that actually starts processes. Nest has nothing quite like it.

---

## 1. Modules become contexts

Nest:

```ts
@Module({
  controllers: [PostsController],
  providers: [PostsService],
  exports: [PostsService],
})
export class PostsModule {}

@Injectable()
export class PostsService {
  constructor(private readonly repo: PostRepository) {}

  findAll() {
    return this.repo.find();
  }

  create(dto: CreatePostDto) {
    return this.repo.save(this.repo.create(dto));
  }
}
```

Phoenix. The context *is* the service. There is no class and no provider list:

```elixir
defmodule MyApp.Blog do
  alias MyApp.Blog.Post
  alias MyApp.Repo

  def list_posts do
    Repo.all(Post)
  end

  def create_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end
end
```

Other code calls `MyApp.Blog.list_posts()`. "Exporting" a service means "this function is public." A function with `defp` is private, which is as close as Elixir gets to not exporting a provider.

**Where the analogy stops.** Do not make a context per database table, and do not make a `PostsService` module that the context merely wraps. One context per business area (`Accounts`, `Blog`, `Billing`). Controllers stay thin and call the context.

---

## 2. Controllers and routing

Nest binds the route on the method:

```ts
@Controller("posts")
export class PostsController {
  constructor(private readonly posts: PostsService) {}

  @Get()
  findAll() {
    return this.posts.findAll();
  }

  @Post()
  create(@Body() dto: CreatePostDto) {
    return this.posts.create(dto);
  }
}
```

Phoenix binds the route in the router, and the controller is a function of `conn`:

```elixir
# lib/my_app_web/router.ex
scope "/api", MyAppWeb do
  pipe_through :api

  get "/posts", PostController, :index
  post "/posts", PostController, :create
end
```

```elixir
defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller

  alias MyApp.Blog

  def index(conn, _params) do
    render(conn, :index, posts: Blog.list_posts())
  end

  def create(conn, %{"post" => attrs}) do
    case Blog.create_post(attrs) do
      {:ok, post} ->
        conn
        |> put_status(:created)
        |> render(:show, post: post)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_view(json: MyAppWeb.ChangesetJSON)
        |> render(:error, changeset: changeset)
    end
  end
end
```

JSON shape lives in a view module, not in a serializer class. Phoenix 1.7+ renders `PostJSON` automatically when the controller is `PostController` and the action is `:index`:

```elixir
defmodule MyAppWeb.PostJSON do
  def index(%{posts: posts}), do: %{data: Enum.map(posts, &data/1)}
  def show(%{post: post}), do: %{data: data(post)}

  defp data(post) do
    %{id: post.id, title: post.title, body: post.body}
  end
end
```

`conn` is the request and the response being built. Every plug and every controller action receives a `conn` and returns a new one. You never mutate it.

**Where the analogy stops.** Path, status, and body are not return values from the action. You thread them through `conn`. Parameter maps use string keys (`"title"`), because they came off the wire.

---

## 3. Dependency injection

Nest:

```ts
constructor(
  private readonly posts: PostsService,
  private readonly mailer: Mailer,
) {}
```

The container constructs the graph. Tests replace providers with `overrideProvider`.

Phoenix has no container. A context function is called by name. When you truly need to swap an implementation (email in tests, a fake payment gateway), define a behaviour and read the module from config:

```elixir
defmodule MyApp.Mailer do
  @callback deliver(String.t(), String.t()) :: :ok | {:error, term()}
end

defmodule MyApp.Notifications do
  def welcome(email) do
    mailer().deliver(email, "welcome")
  end

  defp mailer, do: Application.fetch_env!(:my_app, :mailer)
end
```

```elixir
# config/config.exs
config :my_app, :mailer, MyApp.Mailer.Swoosh

# config/test.exs
config :my_app, :mailer, MyApp.Mailer.Test
```

That is the whole "DI" story. Use it for boundaries that change between environments. Do not use it to pass `Repo` into every function. `MyApp.Repo` is the repo.

**Where the analogy stops.** If you build a container so Phoenix "feels like Nest," you will hide the data flow that Elixir wants you to read top to bottom.

---

## 4. DTOs and validation become changesets

Nest:

```ts
export class CreatePostDto {
  @IsString()
  @MinLength(1)
  title: string;

  @IsString()
  body: string;
}
```

`ValidationPipe` rejects a bad body before your method runs.

Phoenix casts untrusted params into a schema, then validates. The same changeset is used to insert:

```elixir
defmodule MyApp.Blog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :string
    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body])
    |> validate_required([:title, :body])
    |> validate_length(:title, min: 1, max: 200)
  end
end
```

`cast/3` is the allow-list. Fields you do not list are dropped, which is how you avoid mass-assignment. `Repo.insert/1` returns `{:ok, post}` or `{:error, changeset}`. The changeset carries the errors:

```elixir
# changeset.errors
[title: {"can't be blank", [validation: :required]}]
```

For input that is not a database row (a search form, a command), use an embedded schema. Same changeset API, no table.

**Where the analogy stops.** A changeset is not a DTO class you new up. It is a value describing "data in, valid or not, plus how it changes a struct." Validation belongs next to the schema, in the context boundary, not in a global pipe that runs on every body.

---

## 5. Middleware, guards, pipes, interceptors become plugs

Nest splits the request pipeline into four ideas:

| Nest | Job |
| --- | --- |
| Middleware | Runs before the route, can mutate the request |
| Guard | Allows or denies |
| Pipe | Transforms or validates an argument |
| Interceptor | Wraps the call, can change the response |

Phoenix has one idea: a **plug**. A plug is a function `(conn, opts) -> conn`. You stack them in order in a pipeline, a scope, a controller, or a single action.

```elixir
defmodule MyAppWeb.Plugs.Authenticate do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_token) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "unauthorized"})
        |> halt()

      token ->
        assign(conn, :current_user, MyApp.Accounts.get_user_by_session_token(token))
    end
  end
end
```

Router pipelines are how you group plugs the way Nest groups guards on a controller:

```elixir
pipeline :api do
  plug :accepts, ["json"]
end

pipeline :api_auth do
  plug MyAppWeb.Plugs.Authenticate
end

scope "/api", MyAppWeb do
  pipe_through :api

  get "/posts", PostController, :index
end

scope "/api", MyAppWeb do
  pipe_through [:api, :api_auth]

  post "/posts", PostController, :create
end
```

`halt/1` stops the pipeline. Later plugs and the action do not run. That is a guard.

A plug in a controller runs before the action, which covers the interceptor case of "do something around every action":

```elixir
plug :require_owner when action in [:update, :delete]
```

**Where the analogy stops.** There is no separate pipe stage that magically turns a body into a class instance. Parsing and validation happen in the action (or a plug you wrote) via a changeset. One composable abstraction is the point, not four decorator types.

---

## 6. Errors

Nest throws. A filter turns the exception into a response:

```ts
@Catch(NotFoundException)
export class NotFoundFilter implements ExceptionFilter {
  catch(exception: NotFoundException, host: ArgumentsHost) {
    const res = host.switchToHttp().getResponse();
    res.status(404).json({ error: exception.message });
  }
}
```

Phoenix prefers explicit results. Contexts return tuples. `action_fallback` is the filter: if an action returns a tuple it does not know how to turn into a response, the fallback controller handles it.

```elixir
defmodule MyAppWeb.PostController do
  use MyAppWeb, :controller

  action_fallback MyAppWeb.FallbackController

  def show(conn, %{"id" => id}) do
    with {:ok, post} <- MyApp.Blog.fetch_post(id) do
      render(conn, :show, post: post)
    end
  end
end

defmodule MyAppWeb.FallbackController do
  use MyAppWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "not found"})
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: MyAppWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end
end
```

`with` is the sequential "if this fails, stop" form. It replaces a try/catch around several awaited calls.

Raise only for programmer errors and truly unexpected failures. A missing post is `{:error, :not_found}`, not an exception.

---

## 7. Config

Nest's `ConfigModule` loads `.env` and injects `ConfigService`.

Phoenix compiles most config from `config/*.exs`. Secrets and anything that depends on the machine go in `config/runtime.exs`, which runs when the release boots:

```elixir
config :my_app, MyApp.Repo,
  url: System.get_env("DATABASE_URL")
```

Read app config with `Application.fetch_env!(:my_app, :mailer)`. Do not read `System.get_env` from random business functions; read it once at the edge (`runtime.exs`) and pass the value in.

---

## 8. Auth

Nest: a Passport strategy plus `@UseGuards(JwtAuthGuard)`, which sets `req.user`.

Phoenix's default, from `mix phx.gen.auth`, is a session token in a signed cookie, checked by a plug. Routes that need a user use a pipeline:

```elixir
scope "/", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user]

  live "/posts/new", PostLive.Form, :new
end
```

The generated `UserAuth` plug assigns `:current_scope` or `:current_user` on `conn`. LiveViews get the same data through `on_mount`.

Token APIs (mobile, SPA) are a plug that reads `Authorization: Bearer …`, looks the token up, and assigns the user. Libraries exist (`Guardian`, `Joken`). A first version you can read end to end is often a better teacher than a library: hash the token, store it, look it up in the plug.

**Where the analogy stops.** `phx.gen.auth` is session-oriented on purpose. Copying a JWT-on-every-request setup from Nest is a choice you should make because you have a non-browser client, not because it is the Phoenix default.

---

## 9. The database

| Nest (TypeORM or Prisma) | Ecto |
| --- | --- |
| Entity class | `Ecto.Schema` |
| Migration | `priv/repo/migrations/*.exs` |
| Repository | `MyApp.Repo` |
| `find`, `save`, query builder | `Repo.get`, `Repo.insert`, `Ecto.Query` |
| Entity listeners | `Ecto.Multi`, or explicit functions in the context |

```elixir
import Ecto.Query

def list_published do
  Post
  |> where([p], not is_nil(p.published_at))
  |> order_by([p], desc: p.published_at)
  |> Repo.all()
end
```

Queries are data. You can pass them around and add `where` later. `Repo` is the thing that actually hits Postgres.

Several writes that must succeed or fail together use `Ecto.Multi`, which is the replacement for a transaction script scattered across injected repositories:

```elixir
def publish(post, actor) do
  Ecto.Multi.new()
  |> Ecto.Multi.update(:post, Post.publish_changeset(post))
  |> Ecto.Multi.insert(:event, fn %{post: post} ->
    Audit.changeset(%{action: "publish", post_id: post.id, actor_id: actor.id})
  end)
  |> Repo.transaction()
end
```

Generate the boring parts with `mix phx.gen.context Blog Post posts title:string body:text` or `mix phx.gen.json` for an API. Read every file the generator writes before you edit it. That is the Nest CLI schematic, except the output is the code you are expected to own.

---

## 10. Realtime

Nest gateway:

```ts
@WebSocketGateway()
export class RoomGateway {
  @SubscribeMessage("new_msg")
  handle(client: Socket, payload: { body: string }) {
    client.broadcast.emit("new_msg", payload);
  }
}
```

Phoenix channel:

```elixir
defmodule MyAppWeb.RoomChannel do
  use MyAppWeb, :channel

  def join("room:" <> _room_id, _payload, socket) do
    {:ok, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    broadcast!(socket, "new_msg", %{body: body})
    {:noreply, socket}
  end
end
```

The user socket is wired in `endpoint.ex` and `user_socket.ex` (`channel "room:*", MyAppWeb.RoomChannel`). Topic names (`"room:42"`) are the rooms.

`Phoenix.PubSub` is the bus underneath. Any process, including a controller or a job, can broadcast:

```elixir
Phoenix.PubSub.broadcast(MyApp.PubSub, "room:42", {:new_msg, %{body: "hi"}})
```

This is the part of Phoenix that Nest does not match. Channels are a core abstraction, with supervision, back-pressure, and presence, not an add-on gateway.

---

## 11. Background work

| Nest | Phoenix |
| --- | --- |
| `@Cron("0 * * * *")` | Oban cron plugin, or a scheduled job |
| Bull / BullMQ queue | [Oban](https://hexdocs.pm/oban) |
| `onModuleInit` that starts a loop | A `GenServer` (or `Task`) under the supervision tree |

```elixir
defmodule MyApp.Workers.PublishNotice do
  use Oban.Worker, queue: :mailers, max_attempts: 5

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"post_id" => id}}) do
    post = MyApp.Blog.get_post!(id)
    MyApp.Notifications.published(post)
    :ok
  end
end

# enqueue from the context after a successful insert
%{post_id: post.id}
|> MyApp.Workers.PublishNotice.new()
|> Oban.insert()
```

A `GenServer` is for state you keep in memory and messages you handle one at a time (a cache, a connection, a rate limiter). It is not where HTTP requests go, and it is not a Nest provider with fields. If you do not need a process, a normal function is enough.

---

## 12. Testing

Nest builds a testing module and overrides providers. Phoenix starts the application and gives you a connection or a database sandbox.

```elixir
defmodule MyAppWeb.PostControllerTest do
  use MyAppWeb.ConnCase, async: true

  test "lists posts", %{conn: conn} do
    post = MyApp.BlogFixtures.post_fixture()

    conn = get(conn, ~p"/api/posts")

    assert [%{"id" => id}] = json_response(conn, 200)["data"]
    assert id == post.id
  end
end
```

`~p"/api/posts"` is a verified route. If the route does not exist, the test does not compile.

`DataCase` wraps each test in a transaction that rolls back. Context tests call `MyApp.Blog.create_post/1` directly and assert on `{:ok, _}` and `{:error, changeset}`. You rarely need a mock. The mailer behaviour from section 3 is the case where a fake module earns its keep.

---

## 13. LiveView has no Nest equivalent

This is the reason a lot of people pick Phoenix after Nest, and the mapping will not prepare you for it.

LiveView is a process per connected user. You render HTML on the server, handle events, and Phoenix sends the diff. There is no REST round-trip and no client store for that UI.

```elixir
defmodule MyAppWeb.PostLive.Index do
  use MyAppWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, posts: MyApp.Blog.list_posts(), form: new_form())}
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} phx-submit="save">
      <.input field={@form[:title]} label="Title" />
      <.input field={@form[:body]} type="textarea" label="Body" />
      <button>Save</button>
    </.form>

    <ul>
      <li :for={post <- @posts}>{post.title}</li>
    </ul>
    """
  end

  def handle_event("save", %{"post" => attrs}, socket) do
    case MyApp.Blog.create_post(attrs) do
      {:ok, post} ->
        {:noreply,
         socket
         |> update(:posts, &[post | &1])
         |> assign(:form, new_form())}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp new_form, do: to_form(MyApp.Blog.change_post(%MyApp.Blog.Post{}))
end
```

The context did not change. `create_post/1` is the same function a JSON controller would call. LiveView replaces the controller and the React page, not the business layer.

Keep building JSON controllers if you are learning the backend map. Add one LiveView once contexts, changesets, and plugs feel boring.

---

## A feature, translated

Build a JSON `POST /api/posts` that requires a logged-in user, validates a title and body, inserts a row, and returns 201 or 422.

Nest shape you already know:

```text
PostsModule
  PostsController.create(@Body dto)  -> guarded
  PostsService.create(dto)
  CreatePostDto
  Post entity + repository
```

Phoenix shape to build:

```text
router.ex
  pipeline :api
  pipeline :api_auth          # plug, halts with 401
  post "/posts", PostController, :create

PostController.create/2       # pattern-match params, render
MyApp.Blog.create_post/1      # changeset |> Repo.insert()
MyApp.Blog.Post.changeset/2   # cast + validate
PostJSON.show/1
FallbackController            # {:error, changeset} -> 422
```

Walk it from the outside in:

1. The router accepts JSON and runs the auth plug.
2. The plug assigns `:current_user` or halts.
3. The controller receives `%{"post" => %{"title" => ..., "body" => ...}}`.
4. The context casts and validates. Bad data never reaches `INSERT`.
5. `{:ok, post}` becomes 201 via `PostJSON`. `{:error, changeset}` falls through to 422.
6. A test in `ConnCase` hits `~p"/api/posts"` twice: once with no session, once with a bad title.

That is the whole Nest request lifecycle, expressed as functions.

---

## What Nest will not teach you

Learn these on purpose. They are the actual Phoenix/Elixir skills.

1. **Pattern matching.** Function heads and `case` replace `if` chains and exception types. Practice by writing the fallback controller with three `call/2` clauses.
2. **The pipe.** `attrs |> changeset() |> Repo.insert()` is the normal control flow. If you reach for a temporary variable on every line, you are still writing TypeScript.
3. **Immutability.** `assign(conn, :user, user)` returns a new conn. The old one did not change. This is why plugs compose.
4. **Processes, lightly.** Read one `GenServer` (the Hexdocs example is enough) so Oban and LiveView stop feeling like magic. You do not need to write one in week one.
5. **The supervision tree.** Open `lib/my_app/application.ex`. Those children are what Nest's module init vaguely gestures at: Repo, PubSub, Endpoint, Telemetry.
6. **Let it crash.** A bad match in a request fails that request. The supervisor restarts processes that die. You do not write a global `try/catch` around the app.

---

## A two-week practice order

Do these in order. Each one maps back to a section above.

1. Install Elixir and Phoenix. Run `mix phx.new hello`. Make a request hit a controller action you wrote by hand.
2. Generate a context: `mix phx.gen.context Blog Post posts title:string body:text`. Read `blog.ex`, `post.ex`, the migration, and the context test. Run `mix test`.
3. Add one validation (`validate_length`) and one context test that expects `{:error, changeset}`.
4. Generate JSON with `mix phx.gen.json` on a second resource, or add a route to the resource you have. Compare the controller to section 2.
5. Write a plug that halts with 401, attach it with `pipe_through`, and test both the halted and the allowed request.
6. Move one `{:error, _}` into `action_fallback`.
7. Run `mix phx.gen.auth` in a fresh app and read `user_auth.ex` without changing it. Find the plug that loads the user.
8. Only then: one LiveView that lists and creates the same posts, calling the same context.

Skip channels, Oban, and custom JWT until 1–6 are dull.

---

## Cheat sheet

```text
Nest module graph          ->  context functions + router
@Injectable service        ->  def in a context
constructor(private svc)  ->  call the module, or a behaviour in config
DTO + ValidationPipe       ->  changeset
@Entity()                  ->  schema "posts" do ... end
@Repository                ->  MyApp.Repo
@Get("/posts")             ->  get "/posts", PostController, :index
@UseGuards()               ->  plug that halt()s, grouped in a pipeline
middleware / interceptor   ->  plug
throw NotFoundException    ->  {:error, :not_found} + action_fallback
ConfigService              ->  config/*.exs, Application.fetch_env!
Jest testing module        ->  ExUnit + ConnCase
WebSocket gateway          ->  Channel
Bull queue                 ->  Oban
React page + REST          ->  LiveView, if the UI can live on the server
```

When you are unsure where code goes: if it would be in a Nest service or entity, it goes in the context. If it would be in a controller, guard, or interceptor, it goes in `my_app_web`. If it would be a long-lived singleton with its own state, it is a process in the supervision tree, and you should be able to say why a function was not enough.
