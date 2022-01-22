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
#
# puts AstPrinter.new.visit(expr)
