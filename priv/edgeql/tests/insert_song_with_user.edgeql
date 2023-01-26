# edgedb = :query_required_single!
# mapper = LiveBeats.MediaLibrary.Song

with song := (
  insert Song {
    title := <str>$title,
    attribution := <optional str>$attribution,
    album_artist := <optional str>$album_artist,
    artist := <str>$artist,
    duration := <optional int64>$duration,
    position := <optional int64>$position ?? 0,
    status := <SongStatus>$status,
    mp3_url := <str>$mp3_url,
    mp3_filename := <str>$mp3_filename,
    mp3_filepath := <str>$mp3_filepath,
    mp3_filesize := <int64>$mp3_filesize,
    server_ip := <optional inet>$server_ip,
    played_at := <optional datetime>$played_at,
    paused_at := <optional datetime>$paused_at,
    date_recorded := <optional cal::local_datetime>$date_recorded,
    date_released := <optional cal::local_datetime>$date_released,
    inserted_at := <optional cal::local_datetime>$inserted_at ?? cal::to_local_datetime(datetime_current(), 'UTC'),
    updated_at := <optional cal::local_datetime>$updated_at ?? cal::to_local_datetime(datetime_current(), 'UTC'),
    user := (select User filter .id = <uuid>$user_id)
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
  user: {
    id,
  }
}
