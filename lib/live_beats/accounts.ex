defmodule LiveBeats.Accounts do
  alias LiveBeats.Accounts.{
    Events,
    User
  }

  alias LiveBeats.EdgeDB.Accounts, as: AccountsQueries

  @pubsub LiveBeats.PubSub

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(@pubsub, topic(user_id))
  end

  def unsubscribe(user_id) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(user_id))
  end

  defp topic(user_id), do: "user:#{user_id}"

  def get_users_map(client \\ LiveBeats.EdgeDB, user_ids) when is_list(user_ids) do
    client
    |> AccountsQueries.GetUsers.query!(user_ids: user_ids)
    |> Enum.map(&User.from_edgedb/1)
    |> Enum.into(%{}, fn %User{} = u ->
      {u.id, u}
    end)
  end

  def admin?(%User{} = user) do
    user.email in LiveBeats.config([:admin_emails])
  end

  @doc """
  Updates a user public's settings and exectes event.
  """
  def update_public_settings(client \\ LiveBeats.EdgeDB, %User{} = user, attrs) do
    with {:ok, user} <- change_settings(user, attrs),
         {:ok, user} <-
           AccountsQueries.UpdatePublicSettings.query(client,
             username: user.username,
             profile_tagline: user.profile_tagline
           ) do
      user = User.from_edgedb(user)
      LiveBeats.execute(__MODULE__, %Events.PublicSettingsChanged{user: user})
      {:ok, user}
    else
      {:error, _} = error ->
        error
    end
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(client \\ LiveBeats.EdgeDB, id) do
    case get_user(client, id) do
      nil ->
        raise EdgeDB.Error.no_data_error("user #{id} not found")

      user ->
        user
    end
  end

  def get_user(client \\ LiveBeats.EdgeDB, id) do
    client
    |> AccountsQueries.GetUser.query!(id: id)
    |> User.from_edgedb()
  end

  def get_user_by_username(client \\ LiveBeats.EdgeDB, username) do
    client
    |> AccountsQueries.GetUserByUsername.query!(username: username)
    |> User.from_edgedb()
  end

  def get_user_by_username!(client \\ LiveBeats.EdgeDB, username) do
    case get_user_by_username(client, username) do
      nil ->
        raise EdgeDB.ConstraintViolationError.new("User #{username} doesn't exist")

      user ->
        user
    end
  end

  def update_active_profile(client \\ LiveBeats.EdgeDB, current_user, profile_uid)

  def update_active_profile(
        _client,
        %User{active_profile_user: %User{id: same_id}} = current_user,
        same_id
      ) do
    current_user
  end

  def update_active_profile(client, %User{} = current_user, profile_uid) do
    AccountsQueries.UpdateActiveProfile.query!(client, profile_uid: profile_uid)

    broadcast!(
      current_user,
      %Events.ActiveProfileChanged{current_user: current_user, new_profile_user_id: profile_uid}
    )

    %User{current_user | active_profile_user: %User{id: profile_uid}}
  end

  ## User registration

  @doc """
  Registers a user from their GithHub information.
  """
  def register_github_user(client \\ LiveBeats.EdgeDB, primary_email, info, emails, token) do
    %{
      "login" => username,
      "avatar_url" => avatar_url,
      "html_url" => external_homepage_url
    } = info

    name = info["name"] || username

    result =
      case get_user_by_username(username) do
        nil ->
          AccountsQueries.RegisterUser.query(
            client,
            %{
              username: username,
              email: primary_email,
              name: name,
              avatar_url: avatar_url,
              external_homepage_url: external_homepage_url,
              provider: %{
                id: to_string(info["id"]),
                login: username,
                provider: "github",
                name: name,
                meta: %{user: info, emails: emails},
                token: token,
                email: primary_email
              }
            }
          )

        %User{} = user ->
          client
          |> EdgeDB.with_globals(%{"current_user_id" => user.id})
          |> AccountsQueries.UpdateExistingIdentity.query(
            provider: "github",
            token: token
          )
      end

    case result do
      {:ok, user} ->
        {:ok, User.from_edgedb(user)}

      other ->
        other
    end
  end

  def settings_changeset(%User{} = user, attrs) do
    User.settings_changeset(user, attrs)
  end

  defp change_settings(%User{} = user, attrs) do
    user
    |> settings_changeset(attrs)
    |> Ecto.Changeset.apply_action(:edgedb)
  end

  defp broadcast!(%User{} = user, msg) do
    Phoenix.PubSub.broadcast!(@pubsub, topic(user.id), {__MODULE__, msg})
  end
end
