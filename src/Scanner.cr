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
      add_token(match?('=') ? TokenType::BANG_EQUAL : TokenType::BANG)
    when '='
      add_token(match?('=') ? TokenType::EQUAL_EQUAL : TokenType::EQUAL)
    when '<'
      add_token(match?('=') ? TokenType::LESS_EQUAL : TokenType::LESS)
    when '>'
      add_token(match?('=') ? TokenType::GREATER_EQUAL : TokenType::GREATER)
    when '/'
      if match?('/')
        # A comment goes until the end of the line.
        while peek != '\n' && !at_end?
          advance
        end
      else
        add_token(TokenType::SLASH)
      end
    when ' '
    when '\r'
    when '\t'
    when '\n'
      @line += 1
    when '"'
      string
    else
      if digit?(char)
        number
      else
        Lox.error(@line, "Unexpected character.")
      end
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

  private def match?(expected : Char)
    if at_end?
      false
    elsif @source[@current] != expected
      false
    else
      @current += 1
      true
    end
  end

  private def peek
    if at_end?
      '\0'
    else
      @source[@current]
    end
  end

  private def string
    while peek != '"' && !at_end?
      if peek == '\n'
        @line += 1
      end

      advance
    end

    if at_end?
      Lox.error(@line, "Unterminated string.")
      return
    end

    # The closing ".
    advance

    # Trim the surrounding quotes.
    value = @source[@start + 1...@current - 1]
    add_token(TokenType::STRING, value)
  end

  private def digit?(c : Char)
    c >= '0' && c <= '9'
  end

  private def number
    while digit?(peek)
      advance
    end

    # Look for a fractional part.
    if peek == '.' && digit?(peek_next)
      # Consume the "."
      advance

      while digit?(peek)
        advance
      end
    end

    add_token(
      TokenType::NUMBER,
      @source[@start..@current].to_f
    )
  end

  private def peek_next
    if @current + 1 >= @source.size
      '\0'
    else
      @source[@current + 1]
    end
  end
end
