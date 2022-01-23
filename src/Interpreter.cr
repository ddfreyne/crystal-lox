class Interpreter
  include Expr::Visitor
  include Stmt::Visitor

  class RuntimeError < Exception
    getter token

    def initialize(@token : Token, message : String)
      super(message)
    end
  end

  def initialize
    @environment = Environment.new
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

  def evaluate(expr : Expr)
    expr.accept(self)
  end

  def visit_print_stmt(stmt : Stmt::Print) : Void
    value = evaluate(stmt.expression)
    puts(stringify(value))
  end

  def visit_expression_stmt(stmt : Stmt::Expression) : Void
    evaluate(stmt.expression)
  end

  def visit_var_stmt(stmt : Stmt::Var) : Void
    value = nil
    initializer = stmt.initializer
    if initializer
      value = evaluate(initializer)
    end

    @environment.define(stmt.name.lexeme, value)
  end

  def visit_assign(expr : Expr::Assign)
    value = evaluate(expr.value)
    @environment.assign(expr.name, value)
    value
  end

  def visit_binary(expr : Expr::Binary)
    left = evaluate(expr.left)
    right = evaluate(expr.right)

    case expr.operator.type
    when TokenType::PLUS
      if left.is_a?(Float64) && right.is_a?(Float64)
        left + right
      elsif left.is_a?(String) && right.is_a?(String)
        left + right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers or strings")
      end
    when TokenType::MINUS
      if left.is_a?(Float64) && right.is_a?(Float64)
        left - right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers")
      end
    when TokenType::SLASH
      if left.is_a?(Float64) && right.is_a?(Float64)
        left / right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers")
      end
    when TokenType::STAR
      if left.is_a?(Float64) && right.is_a?(Float64)
        left * right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers")
      end
    when TokenType::GREATER
      if left.is_a?(Float64) && right.is_a?(Float64)
        left > right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers")
      end
    when TokenType::GREATER_EQUAL
      if left.is_a?(Float64) && right.is_a?(Float64)
        left >= right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers")
      end
    when TokenType::LESS
      if left.is_a?(Float64) && right.is_a?(Float64)
        left < right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers")
      end
    when TokenType::LESS_EQUAL
      if left.is_a?(Float64) && right.is_a?(Float64)
        left <= right
      else
        raise RuntimeError.new(expr.operator, "Operands must be numbers")
      end
    when TokenType::EQUAL_EQUAL
      equal?(left, right)
    when TokenType::BANG_EQUAL
      !equal?(left, right)
    else
      raise "Internal inconsistency error: unexpected token type #{expr.operator.type}"
    end
  end

  def visit_grouping(expr : Expr::Grouping)
    evaluate(expr.expr)
  end

  def visit_literal(expr : Expr::Literal)
    expr.value
  end

  def visit_unary(expr : Expr::Unary)
    right = evaluate(expr.right)

    case expr.operator.type
    when TokenType::MINUS
      if right.is_a?(Float64)
        -right
      else
        raise RuntimeError.new(expr.operator, "Operand must be a number")
      end
    when TokenType::BANG
      if right.is_a?(Bool)
        !truthy?(right)
      else
        raise RuntimeError.new(expr.operator, "Operand must be a boolean")
      end
    else
      raise "Internal inconsistency error: unexpected token type #{expr.operator.type}"
    end
  end

  def visit_variable(expr : Expr::Variable)
    @environment.get(expr.name)
  end

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
