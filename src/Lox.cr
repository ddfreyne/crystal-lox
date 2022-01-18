require "./Token"
require "./TokenType"
require "./Scanner"

class Lox
  def initialize
    @had_error = false
  end

  def self.report(line : Int32, where : String, message : String)
    STDERR.puts "[line #{line}] Error#{where}: #{message}"
  end

  def self.error(line : Int32, message : String)
    report(line, "", message)
  end

  def run(source)
    scanner = Scanner.new(source)
    scanner.scan_tokens.each do |token|
      puts token.to_s
    end
  end

  def run_prompt
    loop do
      line = gets
      break unless line
      run(line)
      @had_error = false
    end
  end

  def run_file(filename)
    run(File.read(filename))

    if @had_error
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
