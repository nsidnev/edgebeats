# edgedb = :query_single!
# mapper = LiveBeats.MediaLibrary.Song

with current_song := (select Song filter .id = <uuid>$id)
select Song {
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
filter
  .user.id = <uuid>$user_id
    and
  .inserted_at > current_song.inserted_at
order by
  .position asc
limit 1
