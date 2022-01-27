class LoxClass
  include Callable

  getter name
  getter methods

  def initialize(@name : String, @methods : Hash(String, LoxFunction))
  end

  def arity : Int32
    0
  end

  def call(interpreter : Interpreter, arguments : Array(LoxValue))
    instance = LoxInstance.new(self)
    instance
  end

  def find_method(name : String) : LoxFunction | Nil
    @methods[name]?
  end

  def to_s
    @name
  end
end
