# edgedb = :query!
# mapper = LiveBeats.MediaLibrary.Song

update Song
filter
  .id != <uuid>$id and .user.id = <uuid>$user_id
    and
  .position < <int64>$old_position and .position >= <int64>$new_position
set {
  position := .position+1,
  updated_at := cal::to_local_datetime(datetime_current(), 'UTC'),
}
