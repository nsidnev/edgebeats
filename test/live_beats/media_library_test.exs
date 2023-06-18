defmodule LiveBeats.MediaLibraryTest do
  use LiveBeats.DataCase

  import LiveBeats.{
    AccountsFixtures,
    MediaLibraryFixtures
  }

  alias LiveBeats.{
    Accounts,
    MediaLibrary
  }

  alias LiveBeats.MediaLibrary.Song
  alias LiveBeats.MP3Stat

  describe "songs" do
    test "list_profile_songs/1 returns all songs for a profile" do
      user = user_fixture()
      profile = MediaLibrary.get_profile!(user)
      song = song_fixture(%{user: user})
      assert [profile_song] = MediaLibrary.list_profile_songs(profile)
      assert profile_song.id == song.id
    end

    test "get_song!/1 returns the song with given id" do
      song = song_fixture()
      assert MediaLibrary.get_song!(song.id) == song
    end

    test "delete_song/1 deletes the song and decrement the user's songs_count" do
      user = user_fixture()

      song = song_fixture(%{user: user})

      assert :ok =
               MediaLibrary.delete_song(
                 EdgeDB.with_globals(LiveBeats.EdgeDB, %{"current_user_id" => user.id}),
                 song
               )

      assert Accounts.get_user(user.id).songs_count == 0
      assert_raise EdgeDB.Error, fn -> MediaLibrary.get_song!(song.id) end
    end

    test "change_song/1 returns a song changeset" do
      song = song_fixture()
      assert %Ecto.Changeset{} = MediaLibrary.change_song(song)
    end
  end

  describe "expire_songs_older_than/2" do
    test "deletes the songs expired before the required interval" do
      user = user_fixture()
      client = EdgeDB.with_globals(LiveBeats.EdgeDB, %{"is_admin" => true})

      _expired_song_1 = song_fixture(user: user, title: "song1")
      _expired_song_2 = song_fixture(user: user, title: "song2")

      Process.sleep(:timer.seconds(1))

      active_song = song_fixture(user: user, title: "song3")

      MediaLibrary.expire_songs_older_than(client, 1, :second)

      song_id = active_song.id

      assert [%Song{id: ^song_id}] =
               MediaLibrary.list_profile_songs(MediaLibrary.get_profile!(user))
    end

    test "Users song_count is decremented when user songs are deleted" do
      user = user_fixture()
      client = EdgeDB.with_globals(LiveBeats.EdgeDB, %{"current_user_id" => user.id})

      songs_changesets =
        Enum.reduce(["1", "2", "3"], %{}, fn song_number, acc ->
          song_changeset =
            %Song{}
            |> Song.changeset(%{title: "song#{song_number}", artist: "artist_one"})
            |> Song.put_mp3(%MP3Stat{size: 0})

          Map.put_new(acc, song_number, song_changeset)
        end)

      assert {:ok, results} =
               MediaLibrary.import_songs(client, user, songs_changesets, fn one, two ->
                 {one, two}
               end)

      assert Accounts.get_user(user.id).songs_count == 3

      for {_idx, song} <- results do
        assert :ok = MediaLibrary.delete_song(client, song)
      end

      assert Accounts.get_user(user.id).songs_count == 0
    end
  end
end
