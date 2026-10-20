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
import { CreateTaskDto } from "./dto/create-task.dto";
import { UpdateTaskDto } from "./dto/update-task.dto";
import { TasksService } from "./tasks.service";

@Controller("tasks")
export class TasksController {
  constructor(private readonly tasks: TasksService) {}

  @Get()
  async index() {
    return { data: await this.tasks.findAll() };
  }

  @Post()
  @HttpCode(201)
  async create(@Body() dto: CreateTaskDto) {
    return { data: await this.tasks.create(dto) };
  }

  @Patch(":id")
  async update(
    @Param("id", ParseIntPipe) id: number,
    @Body() dto: UpdateTaskDto,
  ) {
    return { data: await this.tasks.update(id, dto) };
  }

  @Delete(":id")
  @HttpCode(204)
  remove(@Param("id", ParseIntPipe) id: number) {
    return this.tasks.remove(id);
  }
}
