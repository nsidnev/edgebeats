defmodule LiveBeats.MediaLibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LiveBeats.MediaLibrary` context.
  """

  alias LiveBeats.Accounts.User
  alias LiveBeats.MediaLibrary.Song

  @doc """
  Generate a song.
  """
  def song_fixture(attrs \\ %{}) do
    {:ok, server_ip} = EctoNetwork.INET.cast(LiveBeats.config([:files, :server_ip]))

    attrs =
      Enum.into(attrs, %{
        album_artist: "some album_artist",
        artist: "some artist",
        date_recorded: ~N[2021-10-26 20:11:00],
        date_released: ~N[2021-10-26 20:11:00],
        duration: 42,
        title: "some title",
        mp3_url: "//example.com/mp3.mp3",
        mp3_filename: "mp3.mp3",
        mp3_filepath: "/data/mp3.mp3",
        server_ip: server_ip,
        status: :stopped
      })

    callback =
      case attrs do
        %{user: %User{id: id}} when is_binary(id) ->
          &LiveBeats.EdgeDB.Tests.insert_song_with_user/1

        _other ->
          &LiveBeats.EdgeDB.Tests.insert_song/1
      end

    {:ok, song} =
      Song
      |> struct!(attrs)
      |> LiveBeats.EdgeDB.Ecto.insert(callback, keep: [:inserted_at, :updated_at])

    song
  end
end
