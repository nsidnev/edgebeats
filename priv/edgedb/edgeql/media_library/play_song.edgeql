# edgedb = :query_required_single!
# mapper = LiveBeats.MediaLibrary.Song

with song := (
  update Song
  filter .id = <uuid>$id
  set {
    status := SongStatus.Playing,
    played_at := datetime_current(),
    updated_at := cal::to_local_datetime(datetime_current(), 'UTC'),
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
    id
  }
}
