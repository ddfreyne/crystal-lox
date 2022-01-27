class Return < Exception
  getter value

  def initialize(@value : LoxValue)
  end
end
