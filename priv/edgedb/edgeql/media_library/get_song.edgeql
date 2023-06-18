select assert_exists(Song filter .id = <uuid>$song_id, message := "Song doesn't exist") {
  *,
  mp3: {
    *
  },
  user: {
    id,
  }
}
