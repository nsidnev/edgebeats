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
  .position asc
limit 1
