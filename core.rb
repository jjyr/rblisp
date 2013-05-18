require 'pry'
require 'pry-nav'

class Env
  @@local_variables = {}

  [:+, :-, :*, :/].each do |op|
    define_method(op){|*args|args.reduce op}
  end

  def list *args
    args
  end

  def [] key
    @@local_variables[key]
  end

  def []= key, value
    @@local_variables[key] = value
  end

  def local_variables? key
    @@local_variables.has_key? key
  end
end

Env.freeze

def new_env_class
  Env.dup
end

def new_env
  new_env_class.new
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

def evaluate arr, env = new_env
  arr = arr.first if arr.is_a?(Array) && arr.size == 1 && !env.respond_to?(arr.first.to_s)
  if !arr.is_a?(Array)
    return env.local_variables?(arr) ? env[arr] : arr
  end
  case arr.first.to_s
  when 'define'
    env[arr[1]] = evaluate(arr[2..-1])
    return
  end

  arr.map! do |token|
    case token
    when Array
      evaluate token, Class.new(env.class).new
    when Symbol
      env.local_variables?(token) ? env[token] : token
    else
      token
    end
  end
  env.send *arr
end

def run str, env = new_env
  evaluate parse(str), env
end

env = new_env

loop do
  p run(gets.chomp, env)
end
