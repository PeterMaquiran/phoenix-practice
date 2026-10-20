import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import {
  UnprocessableEntityException,
  ValidationError,
  ValidationPipe,
} from "@nestjs/common";
import { AppModule } from "./app.module";

function validationMessages(errors: ValidationError[]): string[] {
  return errors.flatMap((error) => [
    ...Object.values(error.constraints ?? {}),
    ...validationMessages(error.children ?? []),
  ]);
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      exceptionFactory: (errors) =>
        new UnprocessableEntityException({
          error: "validation failed",
          messages: validationMessages(errors),
        }),
    }),
  );

  await app.listen(3000);
  console.log("Nest API on http://localhost:3000");
}

bootstrap();
