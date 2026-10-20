import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Patch,
  Post,
} from "@nestjs/common";
import { CreatePostDto } from "./dto/create-post.dto";
import { UpdatePostDto } from "./dto/update-post.dto";
import { PostsService } from "./posts.service";

@Controller("posts")
export class PostsController {
  constructor(private readonly posts: PostsService) {}

  @Get()
  async index() {
    return { data: await this.posts.findAll() };
  }

  @Post()
  @HttpCode(201)
  async create(@Body() dto: CreatePostDto) {
    return { data: await this.posts.create(dto) };
  }

  @Patch(":id")
  async update(
    @Param("id", ParseIntPipe) id: number,
    @Body() dto: UpdatePostDto,
  ) {
    return { data: await this.posts.update(id, dto) };
  }

  @Delete(":id")
  @HttpCode(204)
  remove(@Param("id", ParseIntPipe) id: number) {
    return this.posts.remove(id);
  }
}
