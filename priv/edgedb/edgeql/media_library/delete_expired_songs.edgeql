with songs := (
  delete Song
  filter
    .inserted_at < cal::to_local_datetime(datetime_current() - <duration>$interval, 'UTC')
      and
    .server_ip = <inet>$server_ip
      and
    .user.username not in array_unpack(<array<str>>$admin_usernames)
)
select songs {
  mp3: {
    *
  }
}
