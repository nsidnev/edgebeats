select User {
  *
}
filter .id in array_unpack(<array<uuid>>$user_ids)
