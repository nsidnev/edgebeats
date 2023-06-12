defmodule LiveBeats.EdgeDB do
  use EdgeDBEcto,
    name: __MODULE__,
    queries: true,
    queries_path: Path.join([:code.priv_dir(:live_beats), "edgedb", "edgeql"])

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
end
