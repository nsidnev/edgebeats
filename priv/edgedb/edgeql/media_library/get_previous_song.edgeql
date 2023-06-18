with current_song := <Song><uuid>$song_id
select Song {
  *,
  mp3: {
    *
  },
  user: {
    id,
  }
}
filter
  .user = current_song.user
    and
  .position < current_song.position
order by
  .position desc
limit 1
