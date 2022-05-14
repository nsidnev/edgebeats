defmodule LiveBeats.EdgeDB.Codecs.INET do
  defstruct []

  def new do
    %__MODULE__{}
  end

  def name do
    "default::inet"
  end
end

defimpl EdgeDB.Protocol.Codec, for: LiveBeats.EdgeDB.Codecs.INET do
  alias EdgeDB.Protocol.{
    Codec,
    CodecStorage
  }

  alias LiveBeats.EdgeDB.Codecs.INET

  alias Postgrex.DefaultTypes

  # reuse codec from postgrex
  def encode(_codec, %Postgrex.INET{} = inet, codec_storage) do
    encoded_inet = DefaultTypes.encode_value(inet, Postgrex.Extensions.INET)
    bytes_codec = CodecStorage.get_by_name(codec_storage, "std::bytes")
    Codec.encode(bytes_codec, encoded_inet, codec_storage)
  end

  def encode(codec, inet, codec_storage) when is_binary(inet) do
    {:ok, inet} = EctoNetwork.INET.cast(inet)
    Codec.encode(codec, inet, codec_storage)
  end

  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.Error.internal_client_error(
            "received unknown value to encode as #{inspect(INET.name())}: #{inspect(value)}"
          )
  end

  def decode(_codec, data, codec_storage) do
    bytes_codec = CodecStorage.get_by_name(codec_storage, "std::bytes")
    inet_data = Codec.decode(bytes_codec, data, codec_storage)
    [inet] = DefaultTypes.decode_list(inet_data, Postgrex.Extensions.INET)
    inet
  end
end
