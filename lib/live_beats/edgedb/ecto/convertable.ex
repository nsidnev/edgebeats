defprotocol LiveBeats.EdgeDB.Ecto.Convertable do
  # protocol for converting data from EdgeDB driver to Ecto form
  @spec convert(term(), term()) :: term()
  def convert(type, value)
end

defimpl LiveBeats.EdgeDB.Ecto.Convertable, for: Atom do
  def convert(type, %EdgeDB.Set{}) do
    {:ok, result} = Ecto.Type.cast(type, nil)
    result
  end

  def convert(type, value) do
    {:ok, result} = Ecto.Type.cast(type, value)
    result
  end
end

# support for Ecto.ParameterizedType
defimpl LiveBeats.EdgeDB.Ecto.Convertable, for: Tuple do
  def convert(type, %EdgeDB.Set{}) do
    {:ok, result} = Ecto.Type.cast(type, nil)
    result
  end

  def convert(type, value) do
    {:ok, result} = Ecto.Type.cast(type, value)
    result
  end
end
