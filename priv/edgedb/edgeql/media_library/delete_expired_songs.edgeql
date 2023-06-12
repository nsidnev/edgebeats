# edgedb = :query!
# mapper = LiveBeats.MediaLibrary.Song

with song := (
  delete Song
  filter
    .inserted_at < cal::to_local_datetime(datetime_current() - <duration>$interval, 'UTC')
      and
    .server_ip = <inet>$server_ip
      and
    .user.username not in array_unpack(<array<str>>$admin_usernames)
)
select song {
  current := datetime_current(),
  interval := <duration>$interval,
  compare_time := cal::to_local_datetime(datetime_current() - <duration>$interval, 'UTC'),
  inserted_at,
  title,
  mp3_filepath,
  user: {
    id
  },
}
