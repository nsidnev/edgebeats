# edgedb = :query_required_single!

insert Genre {
  title := <str>$title,
  slug := <str>$slug,
}
