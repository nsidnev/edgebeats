# edgedb = :query_required_single!
# mapper = LiveBeats.MediaLibrary.Song

with
  user := (select User filter .id = <uuid>$user_id),
  song := (
    insert Song {
      title := <str>$title,
      attribution := <optional str>$attribution,
      album_artist := <optional str>$album_artist,
      artist := <str>$artist,
      duration := <optional int64>$duration ?? 0,
      position := <optional int64>$position ?? 0,
      status := <optional SongStatus>$status ?? SongStatus.Stopped,
      mp3_url := <str>$mp3_url,
      mp3_filename := <str>$mp3_filename,
      mp3_filepath := <str>$mp3_filepath,
      mp3_filesize := <int64>$mp3_filesize,
      server_ip := <optional inet>$server_ip,
      played_at := <optional datetime>$played_at,
      paused_at := <optional datetime>$paused_at,
      date_recorded := <optional cal::local_datetime>$date_recorded,
      date_released := <optional cal::local_datetime>$date_released,
      user := user,
    }
  )
select song {
  title,
  attribution,
  album_artist,
  artist,
  duration,
  position,
  status,
  mp3_url,
  mp3_filename,
  mp3_filepath,
  mp3_filesize,
  server_ip,
  played_at,
  paused_at,
  date_recorded,
  date_released,
  inserted_at,
  updated_at,
}
