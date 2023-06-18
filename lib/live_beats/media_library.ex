defmodule LiveBeats.MediaLibrary do
  @moduledoc """
  The MediaLibrary context.
  """

  alias LiveBeats.{
    Accounts,
    MP3Stat
  }

  alias LiveBeats.MediaLibrary.{
    Events,
    Profile,
    Song
  }

  alias LiveBeats.EdgeDB.MediaLibrary, as: MediaLibraryQueries

  require Logger

  @pubsub LiveBeats.PubSub
  @auto_next_threshold_seconds 5

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

  def play_song(client \\ LiveBeats.EdgeDB, song)

  def play_song(client, %Song{id: id}) do
    play_song(client, id)
  end

  def play_song(client, id) do
    playing_song =
      client
      |> MediaLibraryQueries.PlaySong.query!(song_id: id)
      |> Song.from_edgedb()

    elapsed = elapsed_playback(playing_song)
    broadcast!(playing_song.user.id, %Events.Play{song: playing_song, elapsed: elapsed})
    playing_song
  end

  def pause_song(client \\ LiveBeats.EdgeDB, %Song{} = song) do
    MediaLibraryQueries.PauseSong.query!(client, song_id: song.id)
    broadcast!(song.user.id, %Events.Pause{song: song})
  end

  def play_next_song_auto(client \\ LiveBeats.EdgeDB, %Profile{} = profile) do
    song = get_current_active_song(client, profile) || get_first_song(client, profile)

    if song &&
         elapsed_playback(song) >=
           Timex.Duration.to_seconds(song.duration) - @auto_next_threshold_seconds do
      next_song = get_next_song(client, song, profile)
      play_song(next_song)
    end
  end

  def play_prev_song(client \\ LiveBeats.EdgeDB, %Profile{} = profile) do
    song = get_current_active_song(client, profile) || get_first_song(client, profile)

    if prev_song = get_prev_song(client, song, profile) do
      play_song(client, prev_song)
    end
  end

  def play_next_song(client \\ LiveBeats.EdgeDB, %Profile{} = profile) do
    song = get_current_active_song(client, profile) || get_first_song(client, profile)

    if next_song = get_next_song(client, song, profile) do
      play_song(client, next_song)
    end
  end

  def store_mp3(%Song{} = song, tmp_path) do
    File.mkdir_p!(Path.dirname(song.mp3.filepath))
    File.cp!(tmp_path, song.mp3.filepath)
  end

  def put_stats(%Ecto.Changeset{} = changeset, %MP3Stat{} = stat) do
    chset = Song.put_stats(changeset, stat)

    if error = chset.errors[:duration] do
      {:error, %{duration: error}}
    else
      {:ok, chset}
    end
  end

  def import_songs(client \\ LiveBeats.EdgeDB, %Accounts.User{}, changesets, consume_file)
      when is_map(changesets) and is_function(consume_file, 2) do
    songs =
      Enum.map(changesets, fn {ref, chset} ->
        song =
          chset
          |> Song.put_server_ip()
          |> changeset_to_map()
          |> Map.put(:ref, ref)

        Map.put(song, :server_ip, server_ip_to_json(song.server_ip))
      end)

    case MediaLibraryQueries.StoreSongsForImport.query(client, songs: songs) do
      {:ok,
       %{
         user: user,
         songs: songs
       }} ->
        user = Accounts.User.from_edgedb(user)

        songs =
          Enum.map(songs, fn %{song: song, ref: ref} ->
            song = Song.from_edgedb(song)
            consume_file.(ref, fn tmp_path -> store_mp3(song, tmp_path) end)
            {ref, song}
          end)

        broadcast_imported(user, songs)

        {:ok, Enum.into(songs, %{})}

      {:error, error} ->
        {:error, error}
    end
  end

  defp broadcast_imported(%Accounts.User{} = user, songs) do
    songs = Enum.map(songs, &elem(&1, 1))
    broadcast!(user.id, %Events.SongsImported{user_id: user.id, songs: songs})
  end

  def parse_file_name(name) do
    case Regex.split(~r/[-–]/, Path.rootname(name), parts: 2) do
      [title] -> %{title: String.trim(title), artist: nil}
      [title, artist] -> %{title: String.trim(title), artist: String.trim(artist)}
    end
  end

  def list_profile_songs(client \\ LiveBeats.EdgeDB, %Profile{} = profile, limit \\ 100) do
    client
    |> MediaLibraryQueries.ListProfileSongs.query!(
      user_id: profile.user_id,
      limit: limit
    )
    |> Enum.map(&Song.from_edgedb/1)
  end

  def list_active_profiles(client \\ LiveBeats.EdgeDB, opts) do
    client
    |> MediaLibraryQueries.ListActiveProfiles.query!(limit: Keyword.fetch!(opts, :limit))
    |> Enum.map(&Accounts.User.from_edgedb/1)
    |> Enum.map(&get_profile!/1)
  end

  def get_current_active_song(client \\ LiveBeats.EdgeDB, %Profile{user_id: user_id}) do
    client
    |> MediaLibraryQueries.GetCurrentActiveSong.query!(user_id: user_id)
    |> Song.from_edgedb()
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

  def get_song!(client \\ LiveBeats.EdgeDB, id) do
    client
    |> MediaLibraryQueries.GetSong.query!(song_id: id)
    |> Song.from_edgedb()
  end

  def get_first_song(client \\ LiveBeats.EdgeDB, %Profile{user_id: user_id}) do
    client
    |> MediaLibraryQueries.GetFirstSong.query!(user_id: user_id)
    |> Song.from_edgedb()
  end

  def get_last_song(client \\ LiveBeats.EdgeDB, %Profile{user_id: user_id}) do
    client
    |> MediaLibraryQueries.GetLastSong.query!(user_id: user_id)
    |> Song.from_edgedb()
  end

  def get_next_song(client \\ LiveBeats.EdgeDB, %Song{} = song, %Profile{} = profile) do
    next =
      client
      |> MediaLibraryQueries.GetNextSong.query!(song_id: song.id)
      |> Song.from_edgedb()

    next || get_first_song(client, profile)
  end

  def get_prev_song(client \\ LiveBeats.EdgeDB, %Song{} = song, %Profile{} = profile) do
    prev =
      client
      |> MediaLibraryQueries.GetPreviousSong.query!(song_id: song.id)
      |> Song.from_edgedb()

    prev || get_last_song(client, profile)
  end

  def update_song_position(client \\ LiveBeats.EdgeDB, %Song{} = song, new_position) do
    new_position =
      MediaLibraryQueries.UpdateSongPosition.query!(client,
        song_id: song.id,
        new_position: new_position
      )

    broadcast!(song.user.id, %Events.NewPosition{song: %Song{song | position: new_position}})
  end

  def delete_song(client \\ LiveBeats.EdgeDB, %Song{} = song) do
    MediaLibraryQueries.DeleteSong.query!(client, song_id: song.id)
    delete_song_file(song)
    broadcast!(song.user.id, %Events.SongDeleted{song: song})
  end

  def expire_songs_older_than(client \\ LiveBeats.EdgeDB, count, interval)
      when interval in [:month, :day, :second] do
    admin_usernames = LiveBeats.config([:files, :admin_usernames])
    server_ip = LiveBeats.config([:files, :server_ip])

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

    deleted_songs =
      client
      |> MediaLibraryQueries.DeleteExpiredSongs.query!(
        interval: interval,
        server_ip: server_ip,
        admin_usernames: admin_usernames
      )
      |> Enum.map(&Song.from_edgedb/1)

    Enum.each(deleted_songs, &delete_song_file/1)
  end

  defp delete_song_file(song) do
    case File.rm(song.mp3.filepath) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.info(
          "unable to delete song #{song.id} at #{song.mp3.filepath}, got: #{inspect(reason)}"
        )
    end
  end

  def change_song(song_or_changeset, attrs \\ %{})

  def change_song(%Song{} = song, attrs) do
    Song.changeset(song, attrs)
  end

  @keep_changes [:duration, :mp3]
  def change_song(%Ecto.Changeset{} = prev_changeset, attrs) do
    %Song{}
    |> change_song(attrs)
    |> Ecto.Changeset.change(Map.take(prev_changeset.changes, @keep_changes))
  end

  defp broadcast!(user_id, msg) when is_binary(user_id) do
    Phoenix.PubSub.broadcast!(@pubsub, topic(user_id), {__MODULE__, msg})
  end

  defp topic(user_id) when is_binary(user_id), do: "profile:#{user_id}"

  defp changeset_to_map(%Ecto.Changeset{} = changeset) do
    Enum.into(changeset.changes, %{}, fn
      {key, %Ecto.Changeset{} = changeset} ->
        {key, changeset_to_map(changeset)}

      entry ->
        entry
    end)
  end

  defp server_ip_to_json(%Postgrex.INET{} = inet) do
    inet
    |> Postgrex.DefaultTypes.encode_value(Postgrex.Extensions.INET)
    |> Base.encode64()
  end
end
