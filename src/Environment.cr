class Environment
  getter enclosing
  getter values

  def initialize(@enclosing : Environment | Nil = nil)
    @values = {} of String => LoxValue
  end

  def define(name : String, value : LoxValue)
    @values[name] = value
  end

  def assign(name : Token, value : LoxValue)
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

  def get(name : Token) : LoxValue
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

  def get_at(distance : Int32, name : String) : LoxValue
    ancestor(distance).values[name]
  end

  def assign_at(distance : Int32, name : Token, value : LoxValue)
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
