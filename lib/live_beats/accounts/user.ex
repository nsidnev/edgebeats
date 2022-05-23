defmodule LiveBeats.Accounts.User do
  use Ecto.Schema
  use EdgeDBEcto.Mapper

  import Ecto.Changeset

  alias LiveBeats.Accounts.{
    Identity,
    User
  }

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "default::User" do
    field :email, :string
    field :name, :string
    field :username, :string
    field :confirmed_at, :naive_datetime
    field :role, :string, default: "subscriber"
    field :profile_tagline, :string
    field :avatar_url, :string
    field :external_homepage_url, :string
    field :songs_count, :integer

    has_one :active_profile_user, User
    has_many :identities, Identity

    timestamps()
  end

  @doc """
  A user changeset for github registration.
  """
  def github_registration_changeset(info, primary_email, emails, token) do
    %{"login" => username, "avatar_url" => avatar_url, "html_url" => external_homepage_url} = info

    identity_changeset =
      Identity.github_registration_changeset(info, primary_email, emails, token)

    if identity_changeset.valid? do
      params = %{
        "username" => username,
        "email" => primary_email,
        "name" => get_change(identity_changeset, :provider_name),
        "avatar_url" => avatar_url,
        "external_homepage_url" => external_homepage_url
      }

      %User{}
      |> cast(params, [:email, :name, :username, :avatar_url, :external_homepage_url])
      |> validate_required([:email, :name, :username])
      |> validate_username()
      |> validate_email()
      |> put_assoc(:identities, [identity_changeset])
    else
      %User{}
      |> change()
      |> Map.put(:valid?, false)
      |> put_assoc(:identities, [identity_changeset])
    end
  end

  def settings_changeset(%User{} = user, params) do
    user
    |> cast(params, [:username, :profile_tagline])
    |> validate_required([:username, :profile_tagline])
    |> validate_username()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
  end

  def validate_username(changeset) do
    changeset
    |> validate_format(:username, ~r/^[a-zA-Z0-9_-]{2,32}$/)
    |> prepare_changes(fn changeset ->
      case fetch_change(changeset, :profile_tagline) do
        {:ok, _} ->
          changeset

        :error ->
          username = get_field(changeset, :username)
          put_change(changeset, :profile_tagline, "#{username}'s beats")
      end
    end)
  end
end
