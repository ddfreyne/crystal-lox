class Return < Exception
  getter value

  def initialize(@value : String | Nil | Bool | Float64 | Callable)
  end
end
