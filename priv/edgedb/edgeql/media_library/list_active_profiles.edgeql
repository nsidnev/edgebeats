with songs := (
  select Song
  filter .status = SongStatus.playing
  order by .updated_at desc
)
select songs.user {
  id,
  username,
  profile_tagline,
  avatar_url,
  external_homepage_url,
}
limit <int64>$limit
