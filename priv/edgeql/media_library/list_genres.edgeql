# edgedb = :query_required_single!
# mapper = LiveBeats.MediaLibrary.Genre

select Genre {
  title,
  slug,
}
order by .title asc
