class LoxFunction
  include Callable

  def initialize(@declaration : Stmt::Function, @closure : Environment)
  end

  def arity : Int32
    @declaration.params.size
  end

  def call(interpreter : Interpreter, arguments : Array(String | Nil | Bool | Float64 | Callable))
    environment = Environment.new(@closure)
    @declaration.params.zip(arguments) do |param, arg|
      environment.define(param.lexeme, arg)
    end

    begin
      interpreter.execute_block(@declaration.body, environment)
    rescue ret : Return
      return ret.value
    end
  end

  def to_s
    "<fn #{@declaration.name.lexeme}>"
  end
end
