with song := (
  insert Song {
    title := <str>$title,
    attribution := <optional str>$attribution,
    artist := <str>$artist,
    duration := <optional duration>$duration,
    position := <optional int64>$position ?? 0,
    status := <SongStatus>$status,
    server_ip := <optional inet>$server_ip,
    played_at := <optional datetime>$played_at,
    paused_at := <optional datetime>$paused_at,
    date_recorded := <optional cal::local_datetime>$date_recorded,
    date_released := <optional cal::local_datetime>$date_released,
    user := (select User filter .id = <optional uuid>$user_id),
    mp3 := (insert MP3 {
      url := <str>$mp3_url,
      filename := <str>$mp3_filename,
      filepath := <str>$mp3_filepath,
      filesize := <cfg::memory>$mp3_filesize,
    })
  }
)
select song {
  **
}
