# edgedb = :query_required_single
# mapper = LiveBeats.Accounts.User

with active_profile := (select User filter .id = <optional uuid>$profile_uid)
update User
filter .id = <uuid>$id
set {
  active_profile_user := active_profile
}
