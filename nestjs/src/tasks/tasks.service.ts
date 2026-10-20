import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { CreateTaskDto } from "./dto/create-task.dto";
import { UpdateTaskDto } from "./dto/update-task.dto";
import { Task } from "./task.entity";

@Injectable()
export class TasksService {
  constructor(
    @InjectRepository(Task)
    private readonly tasks: Repository<Task>,
  ) {}

  findAll(): Promise<Task[]> {
    return this.tasks.find({ order: { id: "ASC" } });
  }

  async create(dto: CreateTaskDto): Promise<Task> {
    const task = this.tasks.create(dto);
    return this.tasks.save(task);
  }

  async update(id: number, dto: UpdateTaskDto): Promise<Task> {
    const task = await this.tasks.findOneBy({ id });
    if (!task) {
      throw new NotFoundException(`task ${id} not found`);
    }

    Object.assign(task, definedFields(dto));
    await this.tasks.save(task);
    return task;
  }

  async remove(id: number): Promise<void> {
    const result = await this.tasks.delete({ id });
    if (!result.affected) {
      throw new NotFoundException(`task ${id} not found`);
    }
  }
}

function definedFields(dto: object): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(dto).filter(([, value]) => value !== undefined),
  );
}
