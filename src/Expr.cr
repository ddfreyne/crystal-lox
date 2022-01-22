abstract class Expr
  module Visitor
    abstract def visit_binary(expr : Binary)
    abstract def visit_literal(expr : Literal)
    abstract def visit_grouping(expr : Grouping)
    abstract def visit_unary(expr : Unary)
  end

  abstract def accept(visitor : Visitor)

  class Binary < Expr
    getter left
    getter operator
    getter right

    def initialize(@left : Expr, @operator : Token, @right : Expr)
    end

    def accept(visitor : Visitor)
      visitor.visit_binary(self)
    end
  end

  class Grouping < Expr
    getter expr

    def initialize(@expr : Expr)
    end

    def accept(visitor : Visitor)
      visitor.visit_grouping(self)
    end
  end

  class Literal < Expr
    getter value

    # TODO: @value type needs to change
    def initialize(@value : String)
    end

    def accept(visitor : Visitor)
      visitor.visit_literal(self)
    end
  end

  class Unary < Expr
    getter operator
    getter right

    def initialize(@operator : Token, @right : Expr)
    end

    def accept(visitor : Visitor)
      visitor.visit_unary(self)
    end
  end
end

class AstPrinter
  include Expr::Visitor

  def visit(expr : Expr) : String
    expr.accept(self)
  end

  def visit_binary(expr : Expr::Binary) : String
    "(#{expr.operator.lexeme} #{visit(expr.left)} #{visit(expr.right)})"
  end

  def visit_grouping(expr : Expr::Grouping) : String
    "(group #{visit(expr.expr)})"
  end

  def visit_literal(expr : Expr::Literal) : String
    expr.value.inspect
  end

  def visit_unary(expr : Expr::Unary) : String
    "(#{expr.operator.lexeme} #{visit(expr.right)})"
  end
end

# expr = Expr::Binary.new(
#   Expr::Unary.new(
#     Token.new(TokenType::MINUS, "-", nil, 1),
#     Expr::Literal.new("123"),
#   ),
#   Token.new(TokenType::STAR, "*", nil, 1),
#   Expr::Grouping.new(
#     Expr::Literal.new("45.67")
#   )
# )
# puts AstPrinter.new.visit(expr)
