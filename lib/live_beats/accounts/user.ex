defmodule LiveBeats.Accounts.User do
  use Ecto.Schema
  use LiveBeats.EdgeDB.Ecto.Schema

  import Ecto.Changeset

  alias LiveBeats.Accounts.{
    Identity,
    User
  }

  @primary_key {:id, :binary_id, autogenerate: false}

  embedded_schema do
    field :name, :string
    field :username, :string
    field :email, :string
    field :profile_tagline, :string
    field :avatar_url, :string
    field :external_homepage_url, :string
    field :songs_count, :integer

    embeds_one :active_profile_user, User
    embeds_many :identities, Identity

    timestamps()
  end

  def settings_changeset(%User{} = user, params) do
    user
    |> cast(params, [:username, :profile_tagline])
    |> validate_required([:username, :profile_tagline])
    |> validate_username()
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
