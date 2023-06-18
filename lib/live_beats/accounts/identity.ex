defmodule LiveBeats.Accounts.Identity do
  use Ecto.Schema
  use LiveBeats.EdgeDB.Ecto.Schema

  alias LiveBeats.Accounts.User

  @derive {Inspect, except: [:provider_token, :provider_meta]}

  @primary_key {:id, :binary_id, autogenerate: false}

  embedded_schema do
    field :provider, :string
    field :provider_token, :string
    field :provider_login, :string
    field :provider_id, :string
    field :provider_email, :string
    field :provider_meta, :map

    embeds_one :user, User

    timestamps()
  end
end
