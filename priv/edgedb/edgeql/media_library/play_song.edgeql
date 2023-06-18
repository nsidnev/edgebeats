with
  stopped_songs := (
    update Song
    filter
      .status in {SongStatus.playing, SongStatus.paused} and .id != <uuid>$song_id
    set {
      status := SongStatus.stopped
    }
  ),
  playing_song := (
    update Song
    filter .id = <uuid>$song_id
    set {
      status := SongStatus.playing
    }
  )
select playing_song {
  *,
  mp3: {
    *
  },
  user: {
    id,
  }
}
