defmodule LiveBeats.Accounts.Identity do
  use Ecto.Schema
  use EdgeDBEcto.Mapper

  import Ecto.Changeset

  alias LiveBeats.Accounts.{Identity, User}

  # providers
  @github "github"

  @derive {Inspect, except: [:provider_token, :provider_meta]}

  @primary_key {:id, :binary_id, autogenerate: false}

  schema "default::Identity" do
    field :provider, :string
    field :provider_token, :string
    field :provider_email, :string
    field :provider_login, :string
    field :provider_name, :string, virtual: true
    field :provider_id, :string
    field :provider_meta, :map

    belongs_to :user, User

    timestamps()
  end

  @doc """
  A user changeset for github registration.
  """
  def github_registration_changeset(info, primary_email, emails, token) do
    params = %{
      "provider" => @github,
      "provider_meta" => %{"user" => info, "emails" => emails},
      "provider_token" => token,
      "provider_id" => to_string(info["id"]),
      "provider_login" => info["login"],
      "provider_name" => info["name"] || info["login"],
      "provider_email" => primary_email
    }

    %Identity{}
    |> cast(params, [
      :provider,
      :provider_meta,
      :provider_token,
      :provider_email,
      :provider_login,
      :provider_name,
      :provider_id
    ])
    |> validate_required([:provider_token, :provider_email, :provider_name, :provider_id])
  end
end
