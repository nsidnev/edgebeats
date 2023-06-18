with updated_user := (
  update global current_user
  set {
    username := <str>$username,
    profile_tagline := <str>$profile_tagline,
  }
)
select updated_user {
  *
}
