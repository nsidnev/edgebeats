defimpl Plug.Exception, for: EdgeDB.Error do
  def status(%EdgeDB.Error{name: "NoDataError"}), do: 404
  def status(_exception), do: 500
  def actions(_exception), do: []
end
