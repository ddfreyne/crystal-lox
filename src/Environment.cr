class Environment
  def initialize(@enclosing : Environment | Nil = nil)
    @values = {} of String => String | Nil | Bool | Float64
  end

  def define(name : String, value : String | Nil | Bool | Float64)
    @values[name] = value
  end

  def assign(name : Token, value : String | Nil | Bool | Float64)
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

  def get(name : Token) : String | Nil | Bool | Float64
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
end
