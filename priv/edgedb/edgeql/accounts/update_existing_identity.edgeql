
with identity := (
  update Identity
  filter .user = global current_user and .provider = <str>$provider
  set {
      provider_token := <str>$token
    }
)
select global current_user {
  *
}
