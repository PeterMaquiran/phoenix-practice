# Same API, two frameworks

Both apps store posts and tasks in a SQLite file and expose the same routes.

| | NestJS | Phoenix |
| --- | --- | --- |
| Folder | `nestjs/` | `phoenix/` |
| Port | http://localhost:3000 | http://localhost:4000 |
| Database | `nestjs/data.sqlite` | `phoenix/my_app.db` |
| Tables | created on boot by TypeORM `synchronize: true` | created by Ecto migrations |

```
GET    /posts
POST   /posts
PATCH  /posts/:id
DELETE /posts/:id

GET    /tasks
POST   /tasks
PATCH  /tasks/:id
DELETE /tasks/:id
```

Posts take `title` and `body`. Tasks take `title` and an optional `done` boolean.

## Run Nest

```bash
cd nestjs
npm install
npm start
```

## Run Phoenix

```bash
cd phoenix
mix setup
mix phx.server
```

`mix setup` downloads deps, creates `my_app.db`, and runs the migrations. Run it again only when dependencies or migrations change. After that, `mix phx.server` is enough.

## Try both

```bash
curl -s -X POST localhost:3000/posts \
  -H 'content-type: application/json' \
  -d '{"title":"Hello","body":"From Nest"}'

curl -s -X POST localhost:4000/posts \
  -H 'content-type: application/json' \
  -d '{"title":"Hello","body":"From Phoenix"}'

curl -s localhost:3000/tasks
curl -s -X POST localhost:4000/tasks \
  -H 'content-type: application/json' \
  -d '{"title":"Ship the comparison","done":false}'
```

A successful create returns `201` and `{ "data": { ... } }`. A bad body returns `422`. An unknown id returns `404`. Delete returns `204` with an empty body.

## Where each file went

Open these pairs side by side.

| Job | NestJS | Phoenix |
| --- | --- | --- |
| Start the app and connect the database | `nestjs/src/app.module.ts`, `nestjs/src/main.ts` | `phoenix/lib/my_app/application.ex`, `phoenix/config/config.exs`, `phoenix/lib/my_app/repo.ex` |
| Register the posts feature | `nestjs/src/posts/posts.module.ts` | `phoenix/lib/my_app_web/router.ex` |
| HTTP for posts | `nestjs/src/posts/posts.controller.ts` | `phoenix/lib/my_app_web/controllers/post_controller.ex` |
| JSON shape for posts | the object returned by the controller | `phoenix/lib/my_app_web/controllers/post_json.ex` |
| Posts business logic | `nestjs/src/posts/posts.service.ts` | `phoenix/lib/my_app/posts.ex` |
| Posts table and fields | `nestjs/src/posts/post.entity.ts` | `phoenix/lib/my_app/posts/post.ex` and `phoenix/priv/repo/migrations/20261020120000_create_posts.exs` |
| Create rules | `nestjs/src/posts/dto/create-post.dto.ts` | `changeset/2` in `phoenix/lib/my_app/posts/post.ex` |
| Update rules | `nestjs/src/posts/dto/update-post.dto.ts` | the same `changeset/2` |
| Tasks feature | `nestjs/src/tasks/` | `phoenix/lib/my_app/tasks.ex`, `phoenix/lib/my_app/tasks/task.ex`, `phoenix/lib/my_app_web/controllers/task_controller.ex` |
| Turn failures into HTTP | `NotFoundException` and the `ValidationPipe` in `main.ts` | `phoenix/lib/my_app_web/controllers/fallback_controller.ex` |

Tasks mirror posts. Read one Nest module folder, then the matching Phoenix context.

## One request, file by file

`POST /posts` with `{ "title": "Hello", "body": "From Phoenix" }`.

Nest:

1. `AppModule` has already started TypeORM and imported `PostsModule`.
2. `PostsModule` registered `PostsController` and injected `PostsService`.
3. `PostsController.create` runs only after `ValidationPipe` has built a `CreatePostDto`. A bad body never enters the controller.
4. `PostsService.create` uses the injected `Repository<Post>` to insert the row.
5. The controller returns `{ data: post }`. Nest serializes that object.

Phoenix:

1. `MyApp.Application` has already started `MyApp.Repo` and `MyAppWeb.Endpoint`.
2. `router.ex` sends the request through the `:api` pipeline to `PostController.create`.
3. `PostController.create` calls `MyApp.Posts.create_post(params)`.
4. `MyApp.Posts` builds a changeset. `cast` keeps `title` and `body` and drops anything else. `Repo.insert` writes the row, or returns `{:error, changeset}`.
5. `{:ok, post}` renders `PostJSON`. `{:error, changeset}` falls through to `FallbackController`, which responds `422`.

The constructor injection in `PostsService` is a direct function call in Phoenix: `Posts.create_post(params)`.

## Differences you can see in the responses

- Nest rejects unknown JSON keys with `422` because `ValidationPipe` uses `forbidNonWhitelisted`. Phoenix drops unknown keys in `cast/3` and saves the known ones.
- Nest needs a second DTO so update fields are optional. Phoenix uses one changeset: omitted fields stay as they already are on the struct.
- Nest creates the SQLite tables on boot. Phoenix changes the database only when you run the migrations in `phoenix/priv/repo/migrations`.
- A missing post is `throw new NotFoundException(...)` in Nest. Phoenix returns `{:error, :not_found}` and `FallbackController` turns that tuple into `404`.

The longer concept map is in `nestjs-to-phoenix.md`.
