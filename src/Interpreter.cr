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

    @environment = globals
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

  def evaluate(expr : Expr) : String | Nil | Bool | Float64 | Callable
    expr.accept(self)
  end

  # visitor - statements

  def visit_block_stmt(stmt : Stmt::Block) : Void
    execute_block(stmt.stmts, Environment.new(@environment))
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
    function = LoxFunction.new(stmt)
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

  def visit_assign_expr(expr : Expr::Assign) : String | Nil | Bool | Float64 | Callable
    value = evaluate(expr.value)
    @environment.assign(expr.name, value)
    value
  end

  def visit_binary_expr(expr : Expr::Binary) : String | Nil | Bool | Float64 | Callable
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

  def visit_grouping_expr(expr : Expr::Grouping) : String | Nil | Bool | Float64 | Callable
    evaluate(expr.expr)
  end

  def visit_literal_expr(expr : Expr::Literal) : String | Nil | Bool | Float64 | Callable
    expr.value
  end

  def visit_logical_expr(expr : Expr::Logical) : String | Nil | Bool | Float64 | Callable
    left = evaluate(expr.left)

    if expr.operator.type == TokenType::OR
      return left if truthy?(left)
    end

    if expr.operator.type == TokenType::AND
      return left if !truthy?(left)
    end

    evaluate(expr.right)
  end

  def visit_call_expr(expr : Expr::Call) : String | Nil | Bool | Float64 | Callable
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

  def visit_unary_expr(expr : Expr::Unary) : String | Nil | Bool | Float64 | Callable
    right = evaluate(expr.right)

    case expr.operator.type
    when TokenType::MINUS
      if right.is_a?(Float64)
        -right
      else
        raise RuntimeError.new(expr.operator, "Operand must be a number.")
      end
    when TokenType::BANG
      if right.is_a?(Bool)
        !truthy?(right)
      else
        raise RuntimeError.new(expr.operator, "Operand must be a boolean.")
      end
    else
      raise "Internal inconsistency error: unexpected token type #{expr.operator.type}"
    end
  end

  def visit_variable_expr(expr : Expr::Variable) : String | Nil | Bool | Float64 | Callable
    @environment.get(expr.name)
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
end
