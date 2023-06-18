with
  songs_params := <array<json>>$songs,
  starting_position := global current_user.songs_count,
  songs := (
    for song_params_with_index in enumerate(array_unpack(songs_params))
    union (
      with
        idx := song_params_with_index.0,
        song_params := song_params_with_index.1,
        song := (
          insert Song {
            title := <str>song_params["title"],
            attribution := <optional str>json_get(song_params, "attribution"),
            artist := <str>song_params["artist"],
            duration := <duration>(<str>(<optional int32>json_get(song_params, "duration") ?? 0) ++ ' seconds'),
            position := starting_position + idx,
            mp3 := (
              insert MP3 {
                url := <str>song_params["mp3"]["url"],
                filename := <str>song_params["mp3"]["filename"],
                filepath := <str>song_params["mp3"]["filepath"],
                filesize := <cfg::memory><int64>song_params["mp3"]["filesize"],
              }
            ),
            server_ip := <optional inet>song_params["server_ip"],
            date_recorded := <optional cal::local_datetime>json_get(song_params, "date_recorded"),
            date_released := <optional cal::local_datetime>json_get(song_params, "date_released"),
            user := global current_user,
          }
        )
      select {
        song := song,
        ref := <str>song_params["ref"],
      }
    )
  )
select {
  songs := songs {
    ref,
    song: {
      *,
      mp3: {
        *
      },
      user: {
        *
      }
    }
  },
  user := global current_user {
    *
  }
}
