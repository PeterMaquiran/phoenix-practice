import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { join } from "path";
import { Post } from "./posts/post.entity";
import { PostsModule } from "./posts/posts.module";
import { Task } from "./tasks/task.entity";
import { TasksModule } from "./tasks/tasks.module";

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: "better-sqlite3",
      database: join(__dirname, "..", "data.sqlite"),
      entities: [Post, Task],
      synchronize: true,
    }),
    PostsModule,
    TasksModule,
  ],
})
export class AppModule {}
