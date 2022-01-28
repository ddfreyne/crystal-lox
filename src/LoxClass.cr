class LoxClass
  include Callable

  getter name
  getter methods

  def initialize(@name : String, @superclass : LoxClass | Nil, @methods : Hash(String, LoxFunction))
  end

  def arity : Int32
    initializer = find_method("init")
    if initializer
      initializer.arity
    else
      0
    end
  end

  def call(interpreter : Interpreter, arguments : Array(LoxValue))
    instance = LoxInstance.new(self)

    initializer = find_method("init")
    if initializer
      initializer.bind(instance).call(interpreter, arguments)
    end

    instance
  end

  def find_method(name : String) : LoxFunction | Nil
    candidate = @methods[name]?
    return candidate if candidate

    superclass = @superclass
    if superclass
      return superclass.find_method(name)
    end

    nil
  end

  def to_s
    @name
  end
end
