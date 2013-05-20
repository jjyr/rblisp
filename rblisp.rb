require_relative 'core'

env = new_env

line = 0

def getc
  if ARGV.size > 0
    $__file_byte ||= open(ARGV[0])
    $__file_byte.readchar
  else
    STDIN.getc
  end
rescue EOFError
  exit
end

loop do
  line += 1
  print "rblisp :#{line} > " unless ARGV.size > 0
  count = 0
  str = ""
  while char = getc
    if char == '('
      count += 1
    elsif char == ')'
      count -= 1
    elsif char =~ /\s/
      char = ' '
    elsif char == nil
      exit
    end
    str << char
    if count == 0
      str.strip!
      next if str.empty?
      p run(str, env) 
      break
    end
  end
end
