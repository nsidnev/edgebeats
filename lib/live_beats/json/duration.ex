defimpl Jason.Encoder, for: Timex.Duration do
  def encode(%Timex.Duration{} = duration, opts) do
    duration = LiveBeats.MP3Stat.to_mmss(duration)
    Jason.Encode.string(duration, opts)
  end
end
