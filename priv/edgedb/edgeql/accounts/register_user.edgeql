with
  provider_params := <json>$provider,
  user := (
    insert User {
      username := <str>$username,
      email := <cistr>$email,
      name := <str>$name,
      avatar_url := <str>$avatar_url,
      external_homepage_url := <str>$external_homepage_url,
      profile_tagline := <str>$username ++ "'s beats"
    }
  ),
  identity := (
    insert Identity {
      provider := <str>provider_params["provider"],
      provider_id := <str>provider_params["id"],
      provider_token := <str>provider_params["token"],
      provider_email := <str>provider_params["email"],
      provider_login := <str>provider_params["login"],
      provider_meta := <json>provider_params["meta"],
      user := user,
    }
  )
select user {
  *
}
