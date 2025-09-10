defmodule ElixirChat.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :text, null: false
      add :username, :string, null: false
      add :room, :string, null: false

      timestamps()
    end

    create index(:messages, [:room])
    create index(:messages, [:inserted_at])
  end
end
