# edgedb = :query!

update Song
filter .id = <uuid>$id
set {
  status := SongStatus.Paused,
  paused_at := datetime_current(),
  updated_at := cal::to_local_datetime(datetime_current(), 'UTC'),
}
