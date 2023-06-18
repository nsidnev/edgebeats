defmodule LiveBeats.MediaLibrary.MP3 do
  use Ecto.Schema
  use LiveBeats.EdgeDB.Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}

  embedded_schema do
    field :url, :string
    field :filename, :string
    field :filepath, :string
    field :filesize, LiveBeats.EdgeDB.Ecto.Memory
  end
end
