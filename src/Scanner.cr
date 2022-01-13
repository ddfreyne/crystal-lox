class Scanner
  def initialize(@source : String)
    @tokens = [] of Token

    @start = 0
    @current = 0
    @line = 1
  end

  def scan_tokens
    while !at_end?
      @start = @current
      scan_token
    end

    @tokens << Token.new(TokenType::EOF, "", nil, @line)
    @tokens
  end

  private def scan_token
    char = advance
    p [:char, char]
    case char
    when '('
      add_token(TokenType::LEFT_PAREN)
    when ')'
      add_token(TokenType::RIGHT_PAREN)
    when '{'
      add_token(TokenType::LEFT_BRACE)
    when '}'
      add_token(TokenType::RIGHT_BRACE)
    when ','
      add_token(TokenType::COMMA)
    when '.'
      add_token(TokenType::DOT)
    when '-'
      add_token(TokenType::MINUS)
    when '+'
      add_token(TokenType::PLUS)
    when ';'
      add_token(TokenType::SEMICOLON)
    when '*'
      add_token(TokenType::STAR)
    when '!'
      add_token(match('=') ? TokenType::BANG_EQUAL : TokenType::BANG)
    when '='
      add_token(match('=') ? TokenType::EQUAL_EQUAL : TokenType::EQUAL)
    when '<'
      add_token(match('=') ? TokenType::LESS_EQUAL : TokenType::LESS)
    when '>'
      add_token(match('=') ? TokenType::GREATER_EQUAL : TokenType::GREATER)
    else
      Lox.error(@line, "Unexpected character.")
    end
  end

  private def at_end?
    @current >= @source.size
  end

  private def advance
    char = @source[@current]
    @current += 1
    char
  end

  private def add_token(type : TokenType)
    add_token(type, nil)
  end

  private def add_token(type : TokenType, literal : Object)
    text = @source[@start..@current]
    @tokens << Token.new(type, text, literal, @line)
  end

  private def match(expected : Char)
    if at_end?
      false
    elsif @source[@current] != expected
      false
    else
      @current += 1
      true
    end
  end
end
