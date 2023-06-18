select Song {
  *,
  mp3: {
    *
  },
  user: {
    id,
  }
}
filter .user.id = <uuid>$user_id
order by
  .position desc
limit 1
