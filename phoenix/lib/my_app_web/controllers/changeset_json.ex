defmodule MyAppWeb.ChangesetJSON do
  def error(%{changeset: changeset}) do
    %{
      error: "validation failed",
      fields: Ecto.Changeset.traverse_errors(changeset, &interpolate/1)
    }
  end

  defp interpolate({msg, opts}) do
    Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
      opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
    end)
  end
end
