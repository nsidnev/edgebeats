defmodule LiveBeats.EdgeDB.Codecs.SongStatus do
  defstruct []

  def new do
    %__MODULE__{}
  end

  def name do
    "default::SongStatus"
  end
end

defimpl EdgeDB.Protocol.Codec, for: LiveBeats.EdgeDB.Codecs.SongStatus do
  alias EdgeDB.Protocol.{
    Codec,
    CodecStorage
  }

  alias LiveBeats.EdgeDB.Codecs.SongStatus

  @database_values ~w(Stopped Playing Paused)
  @string_values Enum.map(@database_values, &String.downcase/1)
  @atom_values Enum.map(@string_values, &String.to_atom/1)

  @mapping Enum.into(@atom_values ++ @string_values, %{}, &{&1, String.capitalize(to_string(&1))})

  def encode(_codec, value, codec_storage)
      when value in @string_values or value in @atom_values do
    str_codec = CodecStorage.get_by_name(codec_storage, "std::str")
    value = @mapping[value]
    Codec.encode(str_codec, value, codec_storage)
  end

  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.Error.internal_client_error(
            "received unknown value to encode as #{inspect(SongStatus.name())}: #{inspect(value)}"
          )
  end

  def decode(_codec, data, codec_storage) do
    str_codec = CodecStorage.get_by_name(codec_storage, "std::str")
    database_value = Codec.decode(str_codec, data, codec_storage)

    case Enum.find(@mapping, fn {_key, value} -> value == database_value end) do
      {key, _value} ->
        key

      nil ->
        raise EdgeDB.Error.internal_client_error(
                "received unsupported value to decode #{inspect(SongStatus.name())}: #{inspect(database_value)}"
              )
    end
  end
end
