abstract class Expr
  module Visitor
    # TODO: rename these to end with _expr
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

    def initialize(@value : String | Nil | Bool | Float64)
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
