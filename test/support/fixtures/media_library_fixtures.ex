defmodule LiveBeats.MediaLibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveBeats.MediaLibrary` context.
  """

  alias LiveBeats.Accounts.User
  alias LiveBeats.MediaLibrary.Song

  @args ~w(
    title
    attribution
    artist
    duration
    position
    status
    server_ip
    played_at
    paused_at
    date_recorded
    date_released
    user_id
    mp3_url
    mp3_filename
    mp3_filepath
  )a

  @doc """
  Generate a song.
  """
  def song_fixture(attrs \\ %{}) do
    {:ok, server_ip} = EctoNetwork.INET.cast(LiveBeats.config([:files, :server_ip]))

    attrs = Enum.into(attrs, %{})

    args =
      Map.merge(
        %{
          title: "some title",
          attribution: "",
          artist: "some artist",
          duration: Timex.Duration.from_seconds(42),
          position: nil,
          status: :stopped,
          server_ip: server_ip,
          played_at: nil,
          paused_at: nil,
          date_recorded: ~N[2021-10-26 20:11:00],
          date_released: ~N[2021-10-26 20:11:00],
          user_id: nil,
          mp3_url: "//example.com/mp3.mp3",
          mp3_filename: "mp3.mp3",
          mp3_filepath: "/data/mp3.mp3",
          mp3_filesize: 1
        },
        Map.take(attrs, @args)
      )

    {client, args} =
      case attrs do
        %{user: %User{id: id}} ->
          {EdgeDB.with_globals(LiveBeats.EdgeDB, %{"current_user_id" => id}),
           Map.put(args, :user_id, id)}

        _other ->
          {LiveBeats.EdgeDB, args}
      end

    {:ok, song} = Tests.EdgeDB.InsertSong.query(client, args)
    song = Song.from_edgedb(song)

    case attrs do
      %{user: %User{} = user} ->
        %{song | user: user}

      _other ->
        %{song | user: %User{}}
    end
  end
end
