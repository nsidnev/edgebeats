# edgedb = :query_single!
# mapper = LiveBeats.Accounts.User

select User {
  id,
  name,
  username,
  email,
  role,
  profile_tagline,
  active_profile_user,
  avatar_url,
  external_homepage_url,
  confirmed_at,
  inserted_at,
  updated_at,
  songs_count,
}
filter
  .<user[is Identity].provider = <str>$provider
    and
  str_lower(.email) = <str>$email
limit 1
