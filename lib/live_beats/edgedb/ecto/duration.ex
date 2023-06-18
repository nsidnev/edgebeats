defmodule LiveBeats.EdgeDB.Ecto.Duration do
  use Ecto.Type

  def type, do: Timex.Duration

  def cast(duration) when is_integer(duration) do
    {:ok, Timex.Duration.from_seconds(duration)}
  end

  def cast(%Timex.Duration{} = duration), do: {:ok, duration}

  def cast(_other), do: :error

  def load(%Timex.Duration{} = duration) do
    {:ok, duration}
  end

  def dump(_other), do: :error
end
