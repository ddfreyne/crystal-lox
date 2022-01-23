class Environment
  def initialize
    @values = {} of String => String | Nil | Bool | Float64
  end

  def define(name : String, value : String | Nil | Bool | Float64)
    @values[name] = value
  end

  def get(name : Token) : String | Nil | Bool | Float64
    @values.fetch(name.lexeme) do
      raise Interpreter::RuntimeError.new(
        name,
        "Undefined variable '#{name.lexeme}'"
      )
    end
  end
end
