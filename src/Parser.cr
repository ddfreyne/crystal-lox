class Parser
  class ParseError < Exception
  end

  def initialize(@tokens : Array(Token))
    @current = 0
  end

  def parse
    statements = [] of Stmt

    while !at_end?
      statements << statement
    end

    statements
  end

  # expressions

  private def statement
    if match([TokenType::PRINT])
      return print_statement
    end

    expression_statement
  end

  private def print_statement
    value = expression
    consume(TokenType::SEMICOLON, "Expected ';' after value.")
    Stmt::Print.new(value)
  end

  private def expression_statement
    expr = expression
    consume(TokenType::SEMICOLON, "Expected ';' after value.")
    Stmt::Expression.new(expr)
  end

  private def expression
    equality
  end

  private def equality
    expr = comparison

    while match([TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL])
      operator = previous
      right = comparison
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  private def comparison
    expr = term

    while match([TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL])
      operator = previous
      right = term
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  private def term
    expr = factor

    while match([TokenType::MINUS, TokenType::PLUS])
      operator = previous
      right = factor
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  private def factor
    expr = unary

    while match([TokenType::SLASH, TokenType::STAR])
      operator = previous
      right = unary
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  private def unary
    if match([TokenType::BANG, TokenType::MINUS])
      operator = previous
      right = unary
      return Expr::Unary.new(operator, right)
    end

    primary
  end

  private def primary
    if match([TokenType::FALSE])
      Expr::Literal.new(false)
    elsif match([TokenType::TRUE])
      Expr::Literal.new(true)
    elsif match([TokenType::NIL])
      Expr::Literal.new(nil)
    elsif match([TokenType::NUMBER, TokenType::STRING])
      Expr::Literal.new(previous.literal)
    elsif match([TokenType::LEFT_PAREN])
      expr = expression
      consume(TokenType::RIGHT_PAREN, "Expected ')' after expression.")
      Expr::Grouping.new(expr)
    else
      raise error(peek, "Expected expression.")
    end
  end

  # Utilities

  private def previous
    @tokens[@current - 1]
  end

  private def advance
    if at_end?
      previous
    else
      @current += 1
    end
  end

  private def peek
    @tokens[@current]
  end

  private def at_end?
    peek.type == TokenType::EOF
  end

  private def match(token_types : Array(TokenType))
    token_types.each do |token_type|
      if check(token_type)
        advance
        return true
      end
    end

    false
  end

  private def check(token_type : TokenType)
    if at_end?
      false
    else
      peek.type == token_type
    end
  end

  private def consume(token_type : TokenType, message : String)
    if check(token_type)
      return advance
    end

    raise error(peek, message)
  end

  private def error(token : Token, message : String)
    Lox.error(token, message)
    ParseError.new
  end

  # TODO: private def synchronize
end
