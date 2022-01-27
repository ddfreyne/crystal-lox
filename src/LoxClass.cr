class LoxClass
  include Callable

  getter name

  def initialize(@name : String)
  end

  def arity : Int32
    0
  end

  def call(interpreter : Interpreter, arguments : Array(LoxValue))
    instance = LoxInstance.new(self)
    instance
  end

  def to_s
    @name
  end
end
