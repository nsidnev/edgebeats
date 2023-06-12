# edgedb = :query!
# mapper = LiveBeats.Accounts.User

with song := (
  select Song
  filter .status = SongStatus.Playing
  order by .updated_at desc
)
select song.user {
  id,
  username,
  profile_tagline,
  avatar_url,
  external_homepage_url,
}
limit <int64>$limit
