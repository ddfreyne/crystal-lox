abstract class Expr
  module Visitor(T)
    abstract def visit_binary(expr : Binary) : T
    abstract def visit_literal(expr : Literal) : T
  end

  abstract def accept(visitor : Visitor(T)) : T forall T

  class Binary < Expr
    getter left
    getter operator
    getter right

    def initialize(@left : Expr, @operator : Token, @right : Expr)
    end

    def accept(visitor : Visitor(T)) : T forall T
      visitor.visit_binary(self)
    end
  end

  class Literal < Expr
    getter value

    def initialize(@value : String)
    end

    def accept(visitor : Visitor(T)) : T forall T
      visitor.visit_literal(self)
    end
  end
end

# TODO: fake; remove
class FakeVisitor
  include Expr::Visitor(String)

  def visit_binary(expr : Expr::Binary) : String
    "Binary(#{expr.accept(expr.left)}, #{expr.operator}, #{expr.accept(expr.right)})"
  end

  def visit_literal(expr : Expr::Literal) : String
    "Literal(#{expr.value})"
  end
end

# TODO: fake; remove
expr = Expr::Binary.new(Expr::Literal.new("Oo"), Token.new(TokenType::STAR, "*", nil, 0), Expr::Literal.new("Aa"))
expr.accept(FakeVisitor.new)
