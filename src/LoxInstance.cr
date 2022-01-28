class LoxInstance
  def initialize(@klass : LoxClass)
    @fields = {} of String => LoxValue
  end

  def get(name : Token)
    @fields.fetch(name.lexeme) do
      method = @klass.find_method(name.lexeme)
      return method.bind(self) if method

      raise Interpreter::RuntimeError.new(
        name,
        "Undefined property '#{name.lexeme}'."
      )
    end
  end

  def set(name : Token, value : LoxValue)
    @fields[name.lexeme] = value
  end

  def to_s
    "#{@klass.name} instance"
  end
end
