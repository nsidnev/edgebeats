# AUTOGENERATED: DO NOT MODIFY
# Generated by Elixir client for EdgeDB via `mix edgedb.generate` from
#   `priv/edgedb/edgeql/media_library/store_songs_for_import.edgeql`.
defmodule LiveBeats.EdgeDB.MediaLibrary.StoreSongsForImport do
  @query """
  with
    songs_params := <array<json>>$songs,
    starting_position := global current_user.songs_count,
    songs := (
      for song_params_with_index in enumerate(array_unpack(songs_params))
      union (
        with
          idx := song_params_with_index.0,
          song_params := song_params_with_index.1,
          song := (
            insert Song {
              title := <str>song_params["title"],
              attribution := <optional str>json_get(song_params, "attribution"),
              artist := <str>song_params["artist"],
              duration := <duration>(<str>(<optional int32>json_get(song_params, "duration") ?? 0) ++ ' seconds'),
              position := starting_position + idx,
              mp3 := (
                insert MP3 {
                  url := <str>song_params["mp3"]["url"],
                  filename := <str>song_params["mp3"]["filename"],
                  filepath := <str>song_params["mp3"]["filepath"],
                  filesize := <cfg::memory><int64>song_params["mp3"]["filesize"],
                }
              ),
              server_ip := <optional inet>song_params["server_ip"],
              date_recorded := <optional cal::local_datetime>json_get(song_params, "date_recorded"),
              date_released := <optional cal::local_datetime>json_get(song_params, "date_released"),
              user := global current_user,
            }
          )
        select {
          song := song,
          ref := <str>song_params["ref"],
        }
      )
    )
  select {
    songs := songs {
      ref,
      song: {
        *,
        mp3: {
          *
        },
        user: {
          *
        }
      }
    },
    user := global current_user {
      *
    }
  }
  """

  @moduledoc """
  Generated module for the EdgeQL query from
    `priv/edgedb/edgeql/media_library/store_songs_for_import.edgeql`.

  Query:

  ```edgeql
  #{@query}
  ```
  """

  @typedoc """
  ```edgeql
  std::uuid
  ```
  """
  @type uuid() :: binary()

  @typedoc """
  ```edgeql
  std::json
  ```
  """
  @type json() :: any()

  @typedoc """
  ```edgeql
  std::duration
  ```
  """
  @type duration() :: Timex.Duration.t() | integer()

  @typedoc """
  ```edgeql
  scalar type default::SongStatus extending enum<stopped, playing, paused>
  ```
  """
  @type default__song_status() :: String.t() | :stopped | :playing | :paused

  @typedoc """
  ```edgeql
  scalar type default::inet extending std::bytes
  ```
  """
  @type default__inet() :: bitstring()

  @typedoc """
  ```edgeql
  scalar type default::cistr extending std::str
  ```
  """
  @type default__cistr() :: String.t()

  @type result() :: %{
          songs: [
            %{
              ref: String.t() | nil,
              song: %{
                mp3: %{
                  id: uuid(),
                  filename: String.t(),
                  filepath: String.t(),
                  filesize: EdgeDB.ConfigMemory.t(),
                  url: String.t()
                },
                user:
                  %{
                    username: String.t(),
                    email: default__cistr(),
                    profile_tagline: String.t() | nil,
                    avatar_url: String.t() | nil,
                    external_homepage_url: String.t() | nil,
                    id: uuid(),
                    songs_count: integer(),
                    inserted_at: NaiveDateTime.t(),
                    updated_at: NaiveDateTime.t(),
                    name: String.t()
                  }
                  | nil,
                artist: String.t(),
                title: String.t(),
                attribution: String.t() | nil,
                date_recorded: NaiveDateTime.t() | nil,
                date_released: NaiveDateTime.t() | nil,
                paused_at: DateTime.t() | nil,
                played_at: DateTime.t() | nil,
                server_ip: default__inet() | nil,
                id: uuid(),
                position: integer(),
                inserted_at: NaiveDateTime.t(),
                updated_at: NaiveDateTime.t(),
                status: default__song_status(),
                duration: duration()
              }
            }
          ],
          user:
            %{
              username: String.t(),
              email: default__cistr(),
              profile_tagline: String.t() | nil,
              avatar_url: String.t() | nil,
              external_homepage_url: String.t() | nil,
              id: uuid(),
              songs_count: integer(),
              inserted_at: NaiveDateTime.t(),
              updated_at: NaiveDateTime.t(),
              name: String.t()
            }
            | nil
        }

  @type keyword_args() :: [{:songs, [json()]}]

  @type map_args() :: %{
          songs: [json()]
        }

  @type args() :: map_args() | keyword_args()

  @doc """
  Run the query.
  """
  @spec query(
          client :: EdgeDB.client(),
          args :: args(),
          opts :: list(EdgeDB.query_option())
        ) ::
          {:ok, result()}
          | {:error, reason}
        when reason: any()
  def query(client, args, opts \\ []) do
    do_query(client, args, opts)
  end

  @doc """
  Run the query.
  """
  @spec query!(
          client :: EdgeDB.client(),
          args :: args(),
          opts :: list(EdgeDB.query_option())
        ) :: result()
  def query!(client, args, opts \\ []) do
    case do_query(client, args, opts) do
      {:ok, result} ->
        result

      {:error, exc} ->
        raise exc
    end
  end

  @schema [
    user: [
      :username,
      :updated_at,
      :songs_count,
      :profile_tagline,
      :name,
      :inserted_at,
      :id,
      :external_homepage_url,
      :email,
      :avatar_url
    ],
    songs: [
      :ref,
      song: [
        :updated_at,
        :title,
        :status,
        :server_ip,
        :position,
        :played_at,
        :paused_at,
        :inserted_at,
        :id,
        :duration,
        :date_released,
        :date_recorded,
        :attribution,
        :artist,
        user: [
          :username,
          :updated_at,
          :songs_count,
          :profile_tagline,
          :name,
          :inserted_at,
          :id,
          :external_homepage_url,
          :email,
          :avatar_url
        ],
        mp3: [:url, :id, :filesize, :filepath, :filename]
      ]
    ]
  ]
  defp do_query(client, args, opts) do
    opts = Keyword.merge(opts, __transform_result__: [schema: @schema])
    EdgeDB.query_required_single(client, @query, args, opts)
  end
end