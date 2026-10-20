import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { CreatePostDto } from "./dto/create-post.dto";
import { UpdatePostDto } from "./dto/update-post.dto";
import { Post } from "./post.entity";

@Injectable()
export class PostsService {
  constructor(
    @InjectRepository(Post)
    private readonly posts: Repository<Post>,
  ) {}

  findAll(): Promise<Post[]> {
    return this.posts.find({ order: { id: "ASC" } });
  }

  async create(dto: CreatePostDto): Promise<Post> {
    const post = this.posts.create(dto);
    return this.posts.save(post);
  }

  async update(id: number, dto: UpdatePostDto): Promise<Post> {
    const post = await this.posts.findOneBy({ id });
    if (!post) {
      throw new NotFoundException(`post ${id} not found`);
    }

    Object.assign(post, definedFields(dto));
    await this.posts.save(post);
    return post;
  }

  async remove(id: number): Promise<void> {
    const result = await this.posts.delete({ id });
    if (!result.affected) {
      throw new NotFoundException(`post ${id} not found`);
    }
  }
}

function definedFields(dto: object): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(dto).filter(([, value]) => value !== undefined),
  );
}
