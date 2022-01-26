class Environment
  getter enclosing
  getter values

  def initialize(@enclosing : Environment | Nil = nil)
    @values = {} of String => String | Nil | Bool | Float64 | Callable
  end

  def define(name : String, value : String | Nil | Bool | Float64 | Callable)
    @values[name] = value
  end

  def assign(name : Token, value : String | Nil | Bool | Float64 | Callable)
    if @values.has_key?(name.lexeme)
      @values[name.lexeme] = value
    else
      enclosing = @enclosing
      if enclosing
        enclosing.assign(name, value)
      else
        raise Interpreter::RuntimeError.new(
          name,
          "Undefined variable '#{name.lexeme}'."
        )
      end
    end
  end

  def get(name : Token) : String | Nil | Bool | Float64 | Callable
    @values.fetch(name.lexeme) do
      enclosing = @enclosing
      if enclosing
        enclosing.get(name)
      else
        raise Interpreter::RuntimeError.new(
          name,
          "Undefined variable '#{name.lexeme}'."
        )
      end
    end
  end

  def get_at(distance : Int32, name : String) : String | Nil | Bool | Float64 | Callable
    ancestor(distance).values[name]
  end

  def assign_at(distance : Int32, name : Token, value : String | Nil | Bool | Float64 | Callable)
    ancestor(distance).values[name.lexeme] = value
  end

  def ancestor(distance : Int32) : Environment
    environment = self

    distance.times do
      enclosing = environment.enclosing
      if enclosing
        environment = enclosing
      end
    end

    environment
  end
end
