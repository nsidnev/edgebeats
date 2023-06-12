# edgedb = :query_required_single!
# mapper = LiveBeats.MediaLibrary.Song

with
  params := <json>$params,
  song := (
    update Song
    filter .id = <uuid>params["id"]
    set {
      title := <optional str>json_get(params, "title") ?? .title,
      attribution := <optional str>json_get(params, "attribution") ?? .attribution,
      album_artist := <optional str>json_get(params, "album_artist") ?? .album_artist,
      artist := <optional str>json_get(params, "artist") ?? .artist,
      duration := <optional int64>json_get(params, "duration") ?? .duration,
      status := to_status(<optional str>json_get(params, "status")) ?? .status,
      mp3_url := <optional str>json_get(params, "mp3_url") ?? .mp3_url,
      mp3_filename := <optional str>json_get(params, "mp3_filename") ?? .mp3_filename,
      mp3_filepath := <optional str>json_get(params, "mp3_filepath") ?? .mp3_filepath,
      mp3_filesize := <optional int64>json_get(params, "mp3_filesize") ?? .mp3_filesize,
      server_ip := <optional inet>json_get(params, "server_ip") ?? .server_ip,
      played_at := <optional datetime>json_get(params, "played_at") ?? .played_at,
      paused_at := <optional datetime>json_get(params, "paused_at") ?? .paused_at,
      date_recorded := <optional cal::local_datetime>json_get(params, "date_recorded") ?? .date_recorded,
      date_released := <optional cal::local_datetime>json_get(params, "date_released") ?? .date_released,
      inserted_at := <optional cal::local_datetime>json_get(params, "inserted_at") ?? cal::to_local_datetime(datetime_current(), 'UTC'),
      updated_at := <optional cal::local_datetime>json_get(params, "updated_at") ?? cal::to_local_datetime(datetime_current(), 'UTC'),
      user := (select User filter .id = <optional uuid>json_get(params, "user", "id")) ?? .user
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
}
