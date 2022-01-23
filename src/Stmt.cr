abstract class Stmt
  module Visitor
    abstract def visit_expression_stmt(expr : Expression) : Void
    abstract def visit_print_stmt(expr : Print) : Void
  end

  abstract def accept(visitor : Visitor)

  class Expression < Stmt
    getter expression

    def initialize(@expression : Expr)
    end

    def accept(visitor : Visitor)
      visitor.visit_expression_stmt(self)
    end
  end

  class Print < Stmt
    getter expression

    def initialize(@expression : Expr)
    end

    def accept(visitor : Visitor)
      visitor.visit_print_stmt(self)
    end
  end
end
