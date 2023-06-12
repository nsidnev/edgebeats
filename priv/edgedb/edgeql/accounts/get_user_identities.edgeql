# edgedb = :query!
# mapper = LiveBeats.Accounts.Identity

select Identity {
  provider,
  provider_token,
  provider_login,
  provider_email,
  provider_id,
  provider_meta,
  inserted_at,
  updated_at
}
filter .user.id = <uuid>$user_id
