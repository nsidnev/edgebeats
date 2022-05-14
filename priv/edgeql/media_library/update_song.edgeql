# edgedb = :query_required_single!
# mapper = LiveBeats.MediaLibrary.Song

with
  params := <json>$params,
  song := (
    update Song
    filter .id = <uuid>params["id"]
    set {
      title := <str>json_get(params, "title") ?? .title,
      attribution := <optional str>json_get(params, "attribution") ?? .attribution,
      album_artist := <optional str>json_get(params, "album_artist") ?? .album_artist,
      artist := <optional str>json_get(params, "artist") ?? .artist,
      date_recorded := <optional cal::local_datetime>json_get(params, "date_recorded") ?? .date_recorded,
      date_released := <optional cal::local_datetime>json_get(params, "date_released") ?? .date_released,
      updated_at := cal::to_local_datetime(datetime_current(), 'UTC'),
    }
  )
select song {
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
