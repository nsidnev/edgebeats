# edgedb = :query_required_single
# mapper = LiveBeats.Accounts.User

with
  params := <json>$params,
  updated_user := (
    update User
    filter .id = <uuid>params["id"]
    set {
      username := <str>json_get(params, "username") ?? .username,
      profile_tagline := <optional str>json_get(params, "profile_tagline") ?? .profile_tagline,
      updated_at := cal::to_local_datetime(datetime_current(), 'UTC'),
    }
  )
select updated_user {
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
