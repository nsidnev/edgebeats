# edgedb = :query_required_single!
# mapper = LiveBeats.MediaLibrary.Song

select Song {
  title,
  attribution,
  album_artist,
  artist,
  duration,
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
filter .id = <uuid>$id
