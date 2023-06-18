defmodule LiveBeats.EdgeDB do
  @codecs [
    LiveBeats.EdgeDB.Codecs.INET
  ]

  def child_spec(_opts \\ []) do
    %{
      id: __MODULE__,
      start: {EdgeDB, :start_link, [[name: __MODULE__, codecs: @codecs]]}
    }
  end
end
