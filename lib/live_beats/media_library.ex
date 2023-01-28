defmodule LiveBeats.MediaLibrary do
  @moduledoc """
  The MediaLibrary context.
  """

  alias Ecto.Multi

  alias LiveBeats.{
    Accounts,
    MP3Stat
  }

  alias LiveBeats.MediaLibrary.{
    Events,
    Genre,
    Profile,
    Song
  }

  require Logger

  @pubsub LiveBeats.PubSub
  @auto_next_threshold_seconds 5
  @max_songs 30

  defdelegate stopped?(song), to: Song
  defdelegate playing?(song), to: Song
  defdelegate paused?(song), to: Song

  def attach do
    LiveBeats.attach(__MODULE__, to: {Accounts, Accounts.Events.PublicSettingsChanged})
  end

  def handle_execute({Accounts, %Accounts.Events.PublicSettingsChanged{user: user}}) do
    profile = get_profile!(user)
    broadcast!(user.id, %Events.PublicProfileUpdated{profile: profile})
  end

  def subscribe_to_profile(%Profile{} = profile) do
    Phoenix.PubSub.subscribe(@pubsub, topic(profile.user_id))
  end

  def broadcast_ping(%Accounts.User{} = user, rtt, region) do
    if user.active_profile_user do
      broadcast!(
        user.active_profile_user.id,
        {:ping, %{user: user, rtt: rtt, region: region}}
      )
    end
  end

  def unsubscribe_to_profile(%Profile{} = profile) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(profile.user_id))
  end

  def local_filepath(filename_uuid) when is_binary(filename_uuid) do
    dir = LiveBeats.config([:files, :uploads_dir])
    Path.join([dir, "songs", filename_uuid])
  end

  def can_control_playback?(%Accounts.User{} = user, %Song{} = song) do
    user.id == song.user.id
  end

  def play_song(%Song{id: id}) do
    play_song(id)
  end

  def play_song(id) do
    song = get_song!(id)

    {:ok, %{now_playing: new_song}} =
      Multi.new()
      |> Multi.update_all(
        :now_stopped,
        fn %{__conn__: conn} ->
          fn ->
            LiveBeats.EdgeDB.MediaLibrary.stop_song([user_id: song.user.id], edgedb: [conn: conn])
          end
        end,
        []
      )
      |> Multi.update_all(
        :now_playing,
        fn %{__conn__: conn} ->
          fn ->
            LiveBeats.EdgeDB.MediaLibrary.play_song([id: song.id], edgedb: [conn: conn])
          end
        end,
        []
      )
      |> LiveBeats.EdgeDB.transaction()

    elapsed = elapsed_playback(new_song)

    broadcast!(song.user.id, %Events.Play{song: song, elapsed: elapsed})

    new_song
  end

  def pause_song(%Song{} = song) do
    {:ok, _} =
      Multi.new()
      |> Multi.update_all(
        :now_stopped,
        fn %{__conn__: conn} ->
          fn ->
            LiveBeats.EdgeDB.MediaLibrary.stop_song([user_id: song.user.id], edgedb: [conn: conn])
          end
        end,
        []
      )
      |> Multi.update_all(
        :now_paused,
        fn %{__conn__: conn} ->
          fn ->
            LiveBeats.EdgeDB.MediaLibrary.pause_song([id: song.id], edgedb: [conn: conn])
          end
        end,
        []
      )
      |> LiveBeats.EdgeDB.transaction()

    broadcast!(song.user.id, %Events.Pause{song: song})
  end

  def play_next_song_auto(%Profile{} = profile) do
    song = get_current_active_song(profile) || get_first_song(profile)

    if song && elapsed_playback(song) >= song.duration - @auto_next_threshold_seconds do
      song
      |> get_next_song(profile)
      |> play_song()
    end
  end

  def play_prev_song(%Profile{} = profile) do
    song = get_current_active_song(profile) || get_first_song(profile)

    if prev_song = get_prev_song(song, profile) do
      play_song(prev_song)
    end
  end

  def play_next_song(%Profile{} = profile) do
    song = get_current_active_song(profile) || get_first_song(profile)

    if next_song = get_next_song(song, profile) do
      play_song(next_song)
    end
  end

  def store_mp3(%Song{} = song, tmp_path) do
    File.mkdir_p!(Path.dirname(song.mp3_filepath))
    File.cp!(tmp_path, song.mp3_filepath)
  end

  def put_stats(%Ecto.Changeset{} = changeset, %MP3Stat{} = stat) do
    chset = Song.put_stats(changeset, stat)

    if error = chset.errors[:duration] do
      {:error, %{duration: error}}
    else
      {:ok, chset}
    end
  end

  def import_songs(%Accounts.User{} = user, changesets, consume_file)
      when is_map(changesets) and is_function(consume_file, 2) do
    # refetch user for fresh song count
    user = Accounts.get_user!(user.id)

    starting_position = LiveBeats.EdgeDB.MediaLibrary.get_user_songs_count(user_id: user.id) - 1

    multi =
      changesets
      |> Enum.with_index()
      |> Enum.reduce(Ecto.Multi.new(), fn {{ref, chset}, i}, acc ->
        chset =
          chset
          |> Song.put_user(user)
          |> Song.put_mp3_path()
          |> Song.put_server_ip()
          |> Ecto.Changeset.put_change(:position, starting_position + i + 1)

        Ecto.Multi.insert(acc, {:song, ref}, chset,
          callback: &LiveBeats.EdgeDB.MediaLibrary.insert_song_for_user/2
        )
      end)
      |> Ecto.Multi.run(:valid_songs_count, fn _conn, changes ->
        new_songs_count = changes |> Enum.filter(&match?({{:song, _ref}, _}, &1)) |> Enum.count()
        validate_songs_limit(user.songs_count, new_songs_count)
      end)

    case LiveBeats.EdgeDB.transaction(multi) do
      {:ok, results} ->
        songs =
          results
          |> Enum.filter(&match?({{:song, _ref}, _}, &1))
          |> Enum.map(fn {{:song, ref}, song} ->
            consume_file.(ref, fn tmp_path -> store_mp3(song, tmp_path) end)
            {ref, song}
          end)

        broadcast_imported(user, songs)

        {:ok, Enum.into(songs, %{})}

      {:error, failed_op, failed_val, _changes} ->
        failed_op =
          case failed_op do
            {:song, _number} -> "Invalid song (#{failed_val.changes.title})"
            :is_songs_count_updated? -> :invalid
            failed_op -> failed_op
          end

        {:error, {failed_op, failed_val}}
    end
  end

  defp broadcast_imported(%Accounts.User{} = user, songs) do
    songs = Enum.map(songs, fn {_ref, song} -> song end)
    broadcast!(user.id, %Events.SongsImported{user_id: user.id, songs: songs})
  end

  def parse_file_name(name) do
    case Regex.split(~r/[-–]/, Path.rootname(name), parts: 2) do
      [title] -> %{title: String.trim(title), artist: nil}
      [title, artist] -> %{title: String.trim(title), artist: String.trim(artist)}
    end
  end

  def create_genre(attrs \\ %{}) do
    %Genre{}
    |> Genre.changeset(attrs)
    |> EdgeDBEcto.insert(&LiveBeats.EdgeDB.MediaLibrary.insert_genre/1)
  end

  def list_genres do
    LiveBeats.EdgeDB.MediaLibrary.list_genres()
  end

  def list_profile_songs(%Profile{} = profile, limit \\ 100) do
    LiveBeats.EdgeDB.MediaLibrary.list_profile_songs(user_id: profile.user_id, limit: limit)
  end

  def list_active_profiles(opts) do
    LiveBeats.EdgeDB.MediaLibrary.list_active_profiles(limit: Keyword.fetch!(opts, :limit))
    |> Enum.map(&get_profile!/1)
  end

  def get_current_active_song(%Profile{user_id: user_id}) do
    LiveBeats.EdgeDB.MediaLibrary.get_current_active_song(user_id: user_id)
  end

  def get_profile!(%Accounts.User{} = user) do
    %Profile{
      user_id: user.id,
      username: user.username,
      tagline: user.profile_tagline,
      avatar_url: user.avatar_url,
      external_homepage_url: user.external_homepage_url
    }
  end

  def owns_profile?(%Accounts.User{} = user, %Profile{} = profile) do
    user.id == profile.user_id
  end

  def owns_song?(%Profile{} = profile, %Song{} = song) do
    profile.user_id == song.user.id
  end

  def elapsed_playback(%Song{} = song) do
    cond do
      playing?(song) ->
        start_seconds = song.played_at |> DateTime.to_unix()
        System.os_time(:second) - start_seconds

      paused?(song) ->
        DateTime.diff(song.paused_at, song.played_at, :second)

      stopped?(song) ->
        0
    end
  end

  def get_song!(id), do: LiveBeats.EdgeDB.MediaLibrary.get_song(id: id)

  def get_first_song(%Profile{user_id: user_id}) do
    LiveBeats.EdgeDB.MediaLibrary.get_first_song(user_id: user_id)
  end

  def get_last_song(%Profile{user_id: user_id}) do
    LiveBeats.EdgeDB.MediaLibrary.get_last_song(user_id: user_id)
  end

  def get_next_song(%Song{} = song, %Profile{} = profile) do
    next = LiveBeats.EdgeDB.MediaLibrary.get_next_song(id: song.id, user_id: profile.user_id, position: song.position)
    next || get_first_song(profile)
  end

  def get_prev_song(%Song{} = song, %Profile{} = profile) do
    prev = LiveBeats.EdgeDB.MediaLibrary.get_prev_song(id: song.id, user_id: profile.user_id, position: song.position)
    prev || get_last_song(profile)
  end

  def update_song_position(%Song{} = song, new_index) do
    old_index = song.position

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:index, fn %{__conn__: conn}, _changes ->
        case LiveBeats.EdgeDB.MediaLibrary.get_user_songs_count([user_id: song.user_id],
               edgedb: [conn: conn]
             ) do
          count when new_index < count -> {:ok, new_index}
          count -> {:ok, count - 1}
        end
      end)
      |> Ecto.Multi.update_all(
        :dec_positions,
        fn %{_conn__: conn, index: new_index} ->
          fn ->
            LiveBeats.EdgeDB.MediaLibrary.decrease_songs_position_after_update(
              [
                id: song.id,
                user_id: song.user_id,
                old_position: old_index,
                new_position: new_index
              ],
              edgedb: [conn: conn]
            )
          end
        end,
        []
      )
      |> Ecto.Multi.update_all(
        :inc_positions,
        fn %{__conn__: conn, index: new_index} ->
          fn ->
            LiveBeats.EdgeDB.MediaLibrary.increase_songs_position_after_update(
              [
                id: song.id,
                user_id: song.user_id,
                old_position: old_index,
                new_position: new_index
              ],
              edgedb: [conn: conn]
            )
          end
        end,
        []
      )
      |> Ecto.Multi.update_all(
        :position,
        fn %{__conn__: conn, index: new_index} ->
          fn ->
            LiveBeats.EdgeDB.MediaLibrary.set_song_position(
              [id: song.id, position: new_index],
              edgedb: [conn: conn]
            )
          end
        end,
        []
      )

    case LiveBeats.EdgeDB.transaction(multi) do
      {:ok, _} ->
        broadcast!(song.user_id, %Events.NewPosition{song: %Song{song | position: new_index}})
        :ok

      {:error, failed_op, _failed_val, _changes} ->
        {:error, failed_op}
    end
  end

  def update_song(%Song{} = song, attrs) do
    song
    |> Song.changeset(attrs)
    |> EdgeDBEcto.update(&LiveBeats.EdgeDB.MediaLibrary.update_song/1)
  end

  def delete_song(%Song{} = song) do
    delete_song_file(song)
    old_index = song.position

    multi_result =
      Ecto.Multi.new()
      |> Ecto.Multi.delete(:delete, song, callback: &LiveBeats.EdgeDB.MediaLibrary.delete_song/2)
      |> Ecto.Multi.update_all(
        :dec_positions,
        fn %{__conn__: conn} ->
          fn ->
            LiveBeats.EdgeDB.MediaLibrary.decrease_songs_position_after_delete(
              [
                id: song.id,
                user_id: song.user_id,
                old_position: old_index,
              ],
              edgedb: [conn: conn]
            )
          end
        end,
        []
      )
      |> LiveBeats.EdgeDB.transaction()

    case multi_result do
      {:ok, _} ->
        broadcast!(song.user_id, %Events.SongDeleted{song: song})
        :ok

      other ->
        other
    end
  end

  def expire_songs_older_than(count, interval) when interval in [:month, :day, :second] do
    admin_usernames = LiveBeats.config([:files, :admin_usernames])
    server_ip = LiveBeats.config([:files, :server_ip])

    multi_result =
      Ecto.Multi.new()
      |> Ecto.Multi.delete_all(
        :delete_expired_songs,
        fn %{__conn__: conn} ->
          step =
            case interval do
              :month ->
                :months

              :day ->
                :days

              :second ->
                :seconds
            end

          interval =
            Timex.Interval.new(from: DateTime.utc_now(), until: [{step, count}])
            |> Timex.Interval.duration(:duration)

          fn ->
            LiveBeats.EdgeDB.MediaLibrary.delete_expired_songs(
              [interval: interval, server_ip: server_ip, admin_usernames: admin_usernames],
              edgedb: [conn: conn]
            )
          end
        end
      )
      |> LiveBeats.EdgeDB.transaction()

    case multi_result do
      {:ok, transaction_result} ->
        deleted_songs = transaction_result.delete_expired_songs
        Enum.each(deleted_songs, &delete_song_file/1)

      error ->
        error
    end
  end

  defp delete_song_file(song) do
    case File.rm(song.mp3_filepath) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.info(
          "unable to delete song #{song.id} at #{song.mp3_filepath}, got: #{inspect(reason)}"
        )
    end
  end

  def change_song(song_or_changeset, attrs \\ %{})

  def change_song(%Song{} = song, attrs) do
    Song.changeset(song, attrs)
  end

  @keep_changes [:duration, :mp3_filesize, :mp3_filepath]
  def change_song(%Ecto.Changeset{} = prev_changeset, attrs) do
    %Song{}
    |> change_song(attrs)
    |> Ecto.Changeset.change(Map.take(prev_changeset.changes, @keep_changes))
  end

  defp broadcast!(user_id, msg) when is_binary(user_id) do
    Phoenix.PubSub.broadcast!(@pubsub, topic(user_id), {__MODULE__, msg})
  end

  defp topic(user_id) when is_binary(user_id), do: "profile:#{user_id}"

  defp validate_songs_limit(user_songs, new_songs_count) do
    if user_songs + new_songs_count <= @max_songs do
      {:ok, new_songs_count}
    else
      {:error, :songs_limit_exceeded}
    end
  end
end
