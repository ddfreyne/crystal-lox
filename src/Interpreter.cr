class Interpreter
  include Expr::Visitor
  include Stmt::Visitor

  getter globals

  class RuntimeError < Exception
    getter token

    def initialize(@token : Token, message : String)
      super(message)
    end
  end

  def initialize
    @globals = Environment.new

    globals.define("clock", Callable::Builtin::Clock.new)
    globals.define("getc", Callable::Builtin::Getc.new)
    globals.define("chr", Callable::Builtin::Chr.new)

    @environment = globals

    @locals = {} of Expr => Int32
  end

  def interpret(stmts : Array(Stmt))
    stmts.each do |stmt|
      execute(stmt)
    end
  rescue err
    if err.is_a?(RuntimeError)
      Lox.runtime_error(err)
    else
      raise err
    end
  end

  def execute(stmt : Stmt)
    stmt.accept(self)
  end

  def evaluate(expr : Expr) : LoxValue
    expr.accept(self)
  end

  def resolve(expr : Expr, depth : Int32)
    @locals[expr] = depth
  end

  # visitor - statements

  def visit_block_stmt(stmt : Stmt::Block) : Void
    execute_block(stmt.stmts, Environment.new(@environment))
  end

  def visit_class_stmt(stmt : Stmt::Class) : Void
    superclass_expr = stmt.superclass
    superclass = nil

    if superclass_expr
      superclass_candidate = evaluate(superclass_expr)
      if !superclass_candidate.is_a?(LoxClass)
        raise RuntimeError.new(superclass_expr.name, "Superclass must be a class.")
      else
        superclass = superclass_candidate
      end
    end

    @environment.define(stmt.name.lexeme, nil)

    original_environment = @environment
    if superclass
      environment = Environment.new(@environment)
      environment.define("super", superclass)
    else
      environment = @environment
    end

    methods = {} of String => LoxFunction
    stmt.methods.each do |method|
      function = LoxFunction.new(
        method,
        environment,
        method.name.lexeme == "init"
      )
      methods[method.name.lexeme] = function
    end

    klass = LoxClass.new(stmt.name.lexeme, superclass, methods)

    if superclass
      environment = original_environment
    end

    @environment.assign(stmt.name, klass)
  end

  # NOTE: Helper
  def execute_block(stmts : Array(Stmt), environment : Environment)
    previous_environment = @environment
    @environment = environment

    begin
      stmts.each do |stmt|
        execute(stmt)
      end
    ensure
      @environment = previous_environment
    end
  end

  def visit_expression_stmt(stmt : Stmt::Expression) : Void
    evaluate(stmt.expression)
  end

  def visit_function_stmt(stmt : Stmt::Function) : Void
    function = LoxFunction.new(stmt, @environment, false)
    @environment.define(stmt.name.lexeme, function)
  end

  def visit_if_stmt(stmt : Stmt::If) : Void
    if truthy?(evaluate(stmt.condition))
      execute(stmt.then_branch)
    else
      else_branch = stmt.else_branch
      if else_branch
        execute(else_branch)
      end
    end
  end

  def visit_print_stmt(stmt : Stmt::Print) : Void
    value = evaluate(stmt.expression)
    puts(stringify(value))
  end

  def visit_return_stmt(stmt : Stmt::Return) : Void
    value_expr = stmt.value
    value =
      if value_expr
        evaluate(value_expr)
      else
        nil
      end

    raise Return.new(value)
  end

  def visit_var_stmt(stmt : Stmt::Var) : Void
    value = nil
    initializer = stmt.initializer
    if initializer
      value = evaluate(initializer)
    end

    @environment.define(stmt.name.lexeme, value)
  end

  def visit_while_stmt(stmt : Stmt::While) : Void
    while truthy?(evaluate(stmt.condition))
      execute(stmt.body)
    end
  end

  # visitor - expression

  def visit_assign_expr(expr : Expr::Assign) : LoxValue
    value = evaluate(expr.value)

    distance = @locals[expr]?
    if distance
      @environment.assign_at(distance, expr.name, value)
    else
      @globals.assign(expr.name, value)
    end

    value
  end

  def visit_binary_expr(expr : Expr::Binary) : LoxValue
    left = evaluate(expr.left)
    right = evaluate(expr.right)

    case expr.operator.type
    when TokenType::PLUS
      if left.is_a?(Float64) && right.is_a?(Float64)
        left + right
      elsif left.is_a?(String) && right.is_a?(String)
        left + right
      else
        raise RuntimeError.new(expr.operator, "Operands must be two numbers or two strings.")
      end
    when TokenType::MINUS
      if left.is_a?(Float64) && right.is_a?(Float64)
        left - right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers.")
      end
    when TokenType::SLASH
      if left.is_a?(Float64) && right.is_a?(Float64)
        left / right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers.")
      end
    when TokenType::STAR
      if left.is_a?(Float64) && right.is_a?(Float64)
        left * right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers.")
      end
    when TokenType::GREATER
      if left.is_a?(Float64) && right.is_a?(Float64)
        left > right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers.")
      end
    when TokenType::GREATER_EQUAL
      if left.is_a?(Float64) && right.is_a?(Float64)
        left >= right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers.")
      end
    when TokenType::LESS
      if left.is_a?(Float64) && right.is_a?(Float64)
        left < right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers.")
      end
    when TokenType::LESS_EQUAL
      if left.is_a?(Float64) && right.is_a?(Float64)
        left <= right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers.")
      end
    when TokenType::EQUAL_EQUAL
      equal?(left, right)
    when TokenType::BANG_EQUAL
      !equal?(left, right)
    else
      raise "Internal inconsistency error: unexpected token type #{expr.operator.type}"
    end
  end

  def visit_call_expr(expr : Expr::Call) : LoxValue
    callee = evaluate(expr.callee)

    arguments = expr.arguments.map { |arg| evaluate(arg) }

    case callee
    when Callable
      if callee.arity != arguments.size
        raise RuntimeError.new(expr.paren, "Expected #{callee.arity} arguments but got #{arguments.size}.")
      end

      callee.call(self, arguments)
    else
      raise RuntimeError.new(expr.paren, "Can only call functions and classes.")
    end
  end

  def visit_get_expr(expr : Expr::Get) : LoxValue
    object = evaluate(expr.object)
    if object.is_a?(LoxInstance)
      return object.get(expr.name)
    end

    raise RuntimeError.new(expr.name, "Only instances have properties.")
  end

  def visit_grouping_expr(expr : Expr::Grouping) : LoxValue
    evaluate(expr.expr)
  end

  def visit_literal_expr(expr : Expr::Literal) : LoxValue
    expr.value
  end

  def visit_logical_expr(expr : Expr::Logical) : LoxValue
    left = evaluate(expr.left)

    if expr.operator.type == TokenType::OR
      return left if truthy?(left)
    end

    if expr.operator.type == TokenType::AND
      return left if !truthy?(left)
    end

    evaluate(expr.right)
  end

  def visit_set_expr(expr : Expr::Set)
    object = evaluate(expr.object)

    unless object.is_a?(LoxInstance)
      raise RuntimeError.new(expr.name, "Only instances have fields.")
    end

    value = evaluate(expr.value)

    object.set(expr.name, value)
    value
  end

  def visit_super_expr(expr : Expr::Super)
    distance = @locals[expr]

    superclass = @environment.get_at(distance, "super")
    unless superclass.is_a?(LoxClass)
      raise "Internal inconsistency: 'super' is not a class"
    end

    object = @environment.get_at(distance - 1, "this")
    unless object.is_a?(LoxInstance)
      raise "Internal inconsistency: 'this' is not an instance"
    end

    method = superclass.find_method(expr.method.lexeme)
    unless method
      raise RuntimeError.new(expr.method, "Undefined property '#{expr.method.lexeme}'.")
    end

    method.bind(object)
  end

  def visit_this_expr(expr : Expr::This)
    look_up_variable(expr.keyword, expr)
  end

  def visit_unary_expr(expr : Expr::Unary) : LoxValue
    right = evaluate(expr.right)

    case expr.operator.type
    when TokenType::MINUS
      if right.is_a?(Float64)
        -right
      else
        raise RuntimeError.new(expr.operator, "Operand must be a number.")
      end
    when TokenType::BANG
      !truthy?(right)
    else
      raise "Internal inconsistency error: unexpected token type #{expr.operator.type}"
    end
  end

  def visit_variable_expr(expr : Expr::Variable) : LoxValue
    look_up_variable(expr.name, expr)
  end

  # utilities

  private def truthy?(value)
    case value
    when nil
      false
    when false
      false
    else
      true
    end
  end

  private def equal?(a, b)
    a == b
  end

  private def stringify(value)
    case value
    when nil
      "nil"
    when Float64
      value.to_s.sub(/\.0$/, "")
    else
      value.to_s
    end
  end

  private def look_up_variable(name : Token, expr : Expr)
    distance = @locals[expr]?
    if distance
      @environment.get_at(distance, name.lexeme)
    else
      @globals.get(name)
    end
  end
end
