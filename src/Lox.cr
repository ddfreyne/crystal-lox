require "./Token"
require "./TokenType"
require "./Scanner"

require "./Expr"
require "./Stmt"
require "./Parser"

require "./Callable"
require "./Return"
require "./LoxFunction"
require "./LoxClass"
require "./LoxInstance"

alias LoxValue = String | Nil | Bool | Float64 | Callable | LoxInstance

require "./Environment"
require "./Resolver"
require "./Interpreter"

class Lox
  @@had_error = false
  @@had_runtime_error = false

  @@interpreter = Interpreter.new

  def self.report(line : Int32, where : String, message : String)
    STDERR.puts "[line #{line}] Error#{where}: #{message}"
    @@had_error = true
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
  end

  def self.runtime_error(error : Interpreter::RuntimeError)
    STDERR.puts(error.message)
    STDERR.puts("[line #{error.token.line}]")
    @@had_runtime_error = true
  end

  def run(source)
    scanner = Scanner.new(source)
    tokens = scanner.scan_tokens

    parser = Parser.new(tokens)
    stmts = parser.parse
    return if @@had_error

    resolver = Resolver.new(@@interpreter)
    resolver.resolve(stmts)
    return if @@had_error

    @@interpreter.interpret(stmts)
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

    exit 65 if @@had_error
    exit 70 if @@had_runtime_error
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
