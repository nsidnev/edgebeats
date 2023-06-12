# edgedb = :query!

update Song
filter
  .user.id = <uuid>$user_id
    and
  .status in {SongStatus.Playing, SongStatus.Paused}
set {
  status := SongStatus.Stopped,
  updated_at := cal::to_local_datetime(datetime_current(), 'UTC'),
}
