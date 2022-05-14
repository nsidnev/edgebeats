defmodule LiveBeats.EdgeDB do
  use LiveBeats.EdgeDB.Queries, name: __MODULE__

  @codecs [
    LiveBeats.EdgeDB.Codecs.SongStatus,
    LiveBeats.EdgeDB.Codecs.INET
  ]

  def child_spec(_opts \\ []) do
    %{
      id: __MODULE__,
      start: {EdgeDB, :start_link, [[name: __MODULE__, codecs: @codecs]]}
    }
  end

  def transaction(callback, opts \\ []) do
    EdgeDB.transaction(__MODULE__, callback, opts)
  end
end
