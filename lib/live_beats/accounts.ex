defmodule LiveBeats.Accounts do
  import Ecto.Changeset

  alias LiveBeats.Accounts.{
    Events,
    User
  }

  @pubsub LiveBeats.PubSub

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(@pubsub, topic(user_id))
  end

  def unsubscribe(user_id) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(user_id))
  end

  defp topic(user_id), do: "user:#{user_id}"

  def list_users(opts) do
    LiveBeats.EdgeDB.Accounts.list_users(limit: Keyword.fetch!(opts, :limit))
  end

  def get_users_map(user_ids) when is_list(user_ids) do
    LiveBeats.EdgeDB.Accounts.get_users(user_ids: user_ids)
    |> Enum.into(%{}, fn %User{} = u ->
      {u.id, u}
    end)
  end

  def lists_users_by_active_profile(id, opts) do
    LiveBeats.EdgeDB.Accounts.list_users_by_active_profile(
      id: id,
      limit: Keyword.fetch!(opts, :limit)
    )
  end

  def admin?(%User{} = user) do
    user.email in LiveBeats.config([:admin_emails])
  end

  @doc """
  Updates a user public's settings and exectes event.
  """
  def update_public_settings(%User{} = user, attrs) do
    update_result =
      user
      |> change_settings(attrs)
      |> LiveBeats.EdgeDB.Ecto.update(&LiveBeats.EdgeDB.Accounts.update_public_settings/1)

    case update_result do
      {:ok, new_user} ->
        LiveBeats.execute(__MODULE__, %Events.PublicSettingsChanged{user: new_user})
        {:ok, new_user}

      {:error, _} = error ->
        error
    end
  end

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    LiveBeats.EdgeDB.Accounts.get_user_by_email(email: email)
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
  def get_user!(id) do
    case get_user(id) do
      nil ->
        raise EdgeDB.Error.no_data_error("user #{id} not found")

      user ->
        user
    end
  end

  def get_user(id) do
    LiveBeats.EdgeDB.Accounts.get_user_by_id(id: id)
  end

  def get_user_by!(fields) do
    LiveBeats.EdgeDB.Accounts.query_user(query: Enum.into(fields, %{}))
  end

  def update_active_profile(
        %User{active_profile_user: %User{id: same_id}} = current_user,
        same_id
      ) do
    current_user
  end

  def update_active_profile(%User{} = current_user, profile_uid) do
    {:ok, _user} =
      LiveBeats.EdgeDB.Accounts.update_active_profile(
        id: current_user.id,
        profile_uid: profile_uid
      )

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
  def register_github_user(primary_email, info, emails, token) do
    if user = get_user_by_provider(:github, primary_email) do
      update_github_token(user, token)
    else
      info
      |> User.github_registration_changeset(primary_email, emails, token)
      |> LiveBeats.EdgeDB.Ecto.insert(&LiveBeats.EdgeDB.Accounts.register_github_user/1,
        nested: true
      )
    end
  end

  def get_user_by_provider(provider, email) when provider in [:github] do
    LiveBeats.EdgeDB.Accounts.get_user_by_provider(
      provider: to_string(provider),
      email: String.downcase(email)
    )
  end

  def change_settings(%User{} = user, attrs) do
    User.settings_changeset(user, attrs)
  end

  defp update_github_token(%User{} = user, new_token) do
    identity =
      LiveBeats.EdgeDB.Accounts.get_identity_for_user(user_id: user.id, provider: "github")

    {:ok, _} =
      identity
      |> change()
      |> put_change(:provider_token, new_token)
      |> LiveBeats.EdgeDB.Ecto.update(&LiveBeats.EdgeDB.Accounts.update_identity_token/1)

    identities = LiveBeats.EdgeDB.Accounts.get_user_identities(user_id: user.id)

    {:ok, %User{user | identities: identities}}
  end

  defp broadcast!(%User{} = user, msg) do
    Phoenix.PubSub.broadcast!(@pubsub, topic(user.id), {__MODULE__, msg})
  end
end
