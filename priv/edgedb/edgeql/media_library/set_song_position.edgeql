# edgedb = :query_single!
# mapper = LiveBeats.MediaLibrary.Song

update Song
filter .id = <uuid>$id
set {
  position := <int64>$position,
  updated_at := cal::to_local_datetime(datetime_current(), 'UTC'),
}
