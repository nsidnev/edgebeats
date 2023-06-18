# AUTOGENERATED: DO NOT MODIFY
# Generated by Elixir client for EdgeDB via `mix edgedb.generate` from
#   `priv/edgedb/edgeql/media_library/update_song_position.edgeql`.
defmodule LiveBeats.EdgeDB.MediaLibrary.UpdateSongPosition do
  @query """
  with
      current_song := <Song><uuid>$song_id,
      old_position := current_song.position,
      songs_count := global current_user.songs_count,
      new_position := <int32>$new_position if <int32>$new_position < songs_count else songs_count - 1,
      decreased_positions := (
          update Song
          filter .id != current_song.id and .position > old_position and .position <= new_position
          set {
              position := .position - 1
          }
      ),
      increased_positions := (
          update Song
          filter .id != current_song.id and .position < old_position and .position >= new_position
          set {
              position := .position + 1
          }
      ),
      updated_song := (
          update current_song
          set {
              position := new_position
          }
      )
  select new_position
  """

  @moduledoc """
  Generated module for the EdgeQL query from
    `priv/edgedb/edgeql/media_library/update_song_position.edgeql`.

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

  @type keyword_args() :: [{:song_id, uuid()} | {:new_position, integer()}]

  @type map_args() :: %{
          song_id: uuid(),
          new_position: integer()
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
          {:ok, integer() | nil}
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
        ) :: integer() | nil
  def query!(client, args, opts \\ []) do
    case do_query(client, args, opts) do
      {:ok, result} ->
        result

      {:error, exc} ->
        raise exc
    end
  end

  defp do_query(client, args, opts) do
    EdgeDB.query_single(client, @query, args, opts)
  end
end