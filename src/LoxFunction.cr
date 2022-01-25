class LoxFunction
  include Callable

  def initialize(@declaration : Stmt::Function)
  end

  def arity : Int32
    @declaration.params.size
  end

  def call(interpreter : Interpreter, arguments : Array(String | Nil | Bool | Float64 | Callable))
    environment = Environment.new(interpreter.globals)
    @declaration.params.zip(arguments) do |param, arg|
      environment.define(param.lexeme, arg)
    end

    interpreter.execute_block(@declaration.body, environment)
  end

  def to_s
    "<fn #{@declaration.name.lexeme}>"
  end
end
