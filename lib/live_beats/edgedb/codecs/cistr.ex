defmodule LiveBeats.EdgeDB.Codecs.CIStr do
  defstruct []

  def new do
    %__MODULE__{}
  end

  def name do
    "default::cistr"
  end
end

defimpl EdgeDB.Protocol.Codec, for: LiveBeats.EdgeDB.Codecs.CIStr do
  alias EdgeDB.Protocol.{
    Codec,
    CodecStorage
  }

  alias LiveBeats.EdgeDB.Codecs.CIStr

  def encode(_codec, value, codec_storage) when is_binary(value) do
    str_codec = CodecStorage.get_by_name(codec_storage, "std::str")
    Codec.encode(str_codec, String.downcase(value), codec_storage)
  end

  def encode(_codec, value, _codec_storage) do
    raise EdgeDB.Error.internal_client_error(
            "received unknown value to encode as #{inspect(CIStr.name())}: #{inspect(value)}"
          )
  end

  def decode(_codec, data, codec_storage) do
    str_codec = CodecStorage.get_by_name(codec_storage, "std::str")
    Codec.encode(str_codec, data, codec_storage)
  end
end
