defmodule LiveBeats.EdgeDB.Ecto.Memory do
  use Ecto.Type

  def type, do: EdgeDB.ConfigMemory

  def cast(memory_size) when is_integer(memory_size) do
    {:ok, %EdgeDB.ConfigMemory{bytes: memory_size}}
  end

  def cast(%EdgeDB.ConfigMemory{} = memory_size), do: {:ok, memory_size}

  def cast(_other), do: :error

  def load(%EdgeDB.ConfigMemory{} = memory_size) do
    {:ok, memory_size}
  end

  def dump(_other), do: :error
end
