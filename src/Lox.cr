require "./Token"
require "./TokenType"
require "./Scanner"

require "./Expr"
require "./AstPrinter"

require "./Parser"

class Lox
  @@had_error = false

  def self.report(line : Int32, where : String, message : String)
    STDERR.puts "[line #{line}] Error#{where}: #{message}"
  end

  def self.error(token : Token, message : String)
    if token.type == TokenType::EOF
      report(token.line, " at end", message)
    else
      report(token.line, " at '" + token.lexeme + "'", message)
    end
  end

  def self.error(line : Int32, message : String)
    report(line, "", message)
    @@had_error = true
  end

  def run(source)
    scanner = Scanner.new(source)
    tokens = scanner.scan_tokens

    parser = Parser.new(tokens)
    expression = parser.parse

    if @@had_error
      return
    end

    if expression
      puts AstPrinter.new.visit(expression)
    end
  end

  def run_prompt
    loop do
      line = gets
      break unless line
      run(line)
      @@had_error = false
    end
  end

  def run_file(filename)
    run(File.read(filename))

    if @@had_error
      exit 65
    end
  end

  def main
    case ARGV.size
    when 0
      run_prompt
    when 1
      run_file(ARGV[0])
    else
      puts "usage: #{PROGRAM_NAME} [script]"
      exit 64
    end
  end
end
