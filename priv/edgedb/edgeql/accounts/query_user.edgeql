# edgedb = :query_required_single!
# mapper = LiveBeats.Accounts.User

with
  query_params := <json>$query,
  user := (
    select User
    filter
      .id = <optional uuid>json_get(query_params, "id") ?? .id
        and
      .username = <optional str>json_get(query_params, "username") ?? .username
        and
      .email = <optional cistr>json_get(query_params, "email") ?? .email
        and
      .role = <optional str>json_get(query_params, "role") ?? .role
        and
      .inserted_at = <optional cal::local_datetime>json_get(query_params, "inserted_at") ?? .inserted_at
        and
      .updated_at = <optional cal::local_datetime>json_get(query_params, "updated_at") ?? .updated_at
        and
      .songs_count = <optional int64>json_get(query_params, "songs_count") ?? .songs_count
  ),
  user := ((select user filter .name = <optional str>json_get(query_params, "name") ?? .name) ?? user),
  user := ((select user filter .profile_tagline = <optional str>json_get(query_params, "profile_tagline") ?? .profile_tagline) ?? user),
  user := ((select user filter .avatar_url = <optional str>json_get(query_params, "avatar_url") ?? .avatar_url) ?? user),
  user := ((select user filter .external_homepage_url = <optional str>json_get(query_params, "external_homepage_url") ?? .external_homepage_url) ?? user),
  user := ((select user filter .confirmed_at = <optional cal::local_datetime>json_get(query_params, "confirmed_at") ?? .confirmed_at) ?? user)
select user {
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
