defmodule LiveBeats.MediaLibrary.Song do
  use Ecto.Schema
  use LiveBeats.EdgeDB.Ecto.Schema

  import Ecto.Changeset

  alias LiveBeats.Accounts
  alias LiveBeats.MP3Stat

  alias LiveBeats.MediaLibrary.{
    MP3,
    Song
  }

  @primary_key {:id, :binary_id, autogenerate: false}

  embedded_schema do
    field :artist, :string
    field :played_at, :utc_datetime
    field :paused_at, :utc_datetime
    field :date_recorded, :naive_datetime
    field :date_released, :naive_datetime
    field :status, Ecto.Enum, values: [:stopped, :playing, :paused], default: :stopped
    field :title, :string
    field :attribution, :string
    field :server_ip, EctoNetwork.INET
    field :duration, LiveBeats.EdgeDB.Ecto.Duration
    field :position, :integer, default: 0

    embeds_one :user, Accounts.User
    embeds_one :mp3, MP3

    timestamps()
  end

  def playing?(%Song{} = song), do: song.status == :playing
  def paused?(%Song{} = song), do: song.status == :paused
  def stopped?(%Song{} = song), do: song.status == :stopped

  @doc false
  def changeset(song, attrs) do
    song
    |> cast(attrs, [
      :artist,
      :title,
      :attribution,
      :date_recorded,
      :date_released
    ])
    |> validate_required([:artist, :title])
  end

  def put_user(%Ecto.Changeset{} = changeset, %Accounts.User{} = user) do
    put_embed(changeset, :user, user)
  end

  def put_stats(%Ecto.Changeset{} = changeset, %LiveBeats.MP3Stat{} = stat) do
    changeset
    |> put_duration(stat.duration)
    |> put_mp3(stat)
  end

  defp put_duration(%Ecto.Changeset{} = changeset, duration) when is_integer(duration) do
    changeset
    |> Ecto.Changeset.change(%{duration: duration})
    |> Ecto.Changeset.validate_number(:duration,
      greater_than: 0,
      less_than: 1200,
      message: "must be less than 20 minutes"
    )
  end

  def put_mp3(%Ecto.Changeset{} = changeset, %MP3Stat{} = stat) do
    filename = Ecto.UUID.generate() <> ".mp3"
    filepath = LiveBeats.MediaLibrary.local_filepath(filename)

    Ecto.Changeset.put_embed(changeset, :mp3, %{
      url: mp3_url(filename),
      filename: filename,
      filepath: filepath,
      filesize: stat.size
    })
  end

  def put_server_ip(%Ecto.Changeset{} = changeset) do
    server_ip = LiveBeats.config([:files, :server_ip])
    Ecto.Changeset.cast(changeset, %{server_ip: server_ip}, [:server_ip])
  end

  defp mp3_url(filename) do
    %{scheme: scheme, host: host, port: port} = Enum.into(LiveBeats.config([:files, :host]), %{})
    URI.to_string(%URI{scheme: scheme, host: host, port: port, path: "/files/#{filename}"})
  end
end
