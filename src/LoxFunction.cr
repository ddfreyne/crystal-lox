class LoxFunction
  include Callable

  def initialize(
    @declaration : Stmt::Function,
    @closure : Environment,
    @is_initializer : Bool
  )
  end

  def arity : Int32
    @declaration.params.size
  end

  def call(interpreter : Interpreter, arguments : Array(LoxValue))
    environment = Environment.new(@closure)
    @declaration.params.zip(arguments) do |param, arg|
      environment.define(param.lexeme, arg)
    end

    begin
      interpreter.execute_block(@declaration.body, environment)
    rescue ret : Return
      if @is_initializer
        return @closure.get_at(0, "this")
      end

      return ret.value
    end

    if @is_initializer
      @closure.get_at(0, "this")
    else
      nil
    end
  end

  def bind(instance : LoxInstance)
    environment = Environment.new(@closure)
    environment.define("this", instance)
    LoxFunction.new(@declaration, environment, @is_initializer)
  end

  def to_s
    "<fn #{@declaration.name.lexeme}>"
  end
end
