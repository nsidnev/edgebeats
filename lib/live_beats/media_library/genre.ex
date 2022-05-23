defmodule LiveBeats.MediaLibrary.Genre do
  use Ecto.Schema
  use EdgeDBEcto.Mapper

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "default::Genre" do
    field :title, :string
    field :slug, :string
  end

  @doc false
  def changeset(song, attrs) do
    song
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> put_slug()
  end

  defp put_slug(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp put_slug(%Ecto.Changeset{valid?: true} = changeset) do
    if title = get_change(changeset, :title) do
      put_change(changeset, :slug, Phoenix.Naming.underscore(title))
    else
      changeset
    end
  end
end
