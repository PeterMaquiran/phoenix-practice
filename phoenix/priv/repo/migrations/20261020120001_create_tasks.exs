defmodule MyApp.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :title, :string, null: false
      add :done, :boolean, null: false, default: false
    end
  end
end
