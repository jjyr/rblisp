require 'pry'
require 'pry-nav'

Env = Class.new do
  [:+, :-, :*, :/].each do |op|
    define_method(op){|*args|args.reduce op}
  end

  def list *args
    args
  end

  def define *args
  end
end

class Array
  alias _inspect inspect
  def inspect
    "(#{_inspect[1..-2]})"
  end
end

def parse_token str, vals = [], env
  val = ""
  loop do
    head = str.shift
    case head
    when '('
      vals << parse_token(str, env)
    when ' ', ')'
      vals << (val =~ /\d+|\A".+"\z/ ? eval(val) : val.to_sym) unless val.empty?
      val = ""
      return vals.size == 1 ? vals.first : vals if head == ')'
    else
      val << head
    end
  end
end

def parse str
  str << ")"
  str = str.each_char.to_a
  parse_token str, Env.new
end

def evaluate arr, env = Env.new
  return arr unless arr.is_a? Array
  p arr
  case arr.first.to_s
  when 'define'
    p arr
  end

  arr.map! do |token|
    case token
    when Array
      evaluate token
    else
      token
    end
  end
  env.send *arr
end

def run str, env = Env.new
  evaluate parse(str), env
end

env = Env.new

loop do
  p run(gets.chomp, env)
end
