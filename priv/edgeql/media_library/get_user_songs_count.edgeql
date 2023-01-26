# edgedb = :query_required_single!
# mapper = LiveBeats.MediaLibrary.Song

select count(Song)
filter .user.id = <uuid>$user_id
