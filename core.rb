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

  def quote token
    token
  end

  def atom atom
    atom.is_a? Symbol
  end

  def eq elem1, elem2
    elem1 == elem2
  end
  
  def car x
    x.first
  end

  def cdr x
    x.last
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
  alias to_s _inspect
  def inspect
    "(#{map(&:inspect).join ' '})"
  end

  def to_token
    token = "["
    each do |t|
      token << "#{t.to_token},"
    end
    token[-1] = "]"
    token
  end
end

class String
  alias to_token inspect
end

class Numeric
  alias to_token to_s
end

class Symbol
  def to_token
    ":#{self}"
  end
  alias inspect to_s
end

def parse_token str, vals = [], env
  val = ""
  loop do
    head = str.shift
    case head
    when '('
      vals << parse_token(str, env)
    when ' ', ')'
      vals << (val =~ /\d+|\A["|'].+["|']\z/ ? eval(val) : val.to_sym) unless val.empty?
      val = ""
      return vals if head == ')'
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
  if arr.is_a?(Array) && arr.size == 1 #&& !env.respond_to?(arr.first.to_s, true)
    arr = arr.first 
    if !arr.is_a?(Array)
      return env.local_variables?(arr) ? env[arr] : arr
    else
      return evaluate arr, Class.new(env.class).new
    end
  end
  case arr.first
  when :define
    if arr[1].is_a? Array
      p env
      p arr[1]

      env.class.class_eval %Q{ 
        def #{arr[1].shift} #{arr[1].join ", "}
          #{arr[2..-1].map{|expr| "evaluate([#{expr.map(&:to_token).join ","}])"}.join ";"}
        end
      }
    else
      #binding.pry
      env[arr[1]] = evaluate(arr[2..-1])
    end
    return
  when :lambda
    return env.instance_eval "->(#{arr[1].join ","}){evaluate([:#{arr[2].join ","}])}"
  else
    unless arr.first.is_a?(Symbol) && env.respond_to?(arr.first, true) || !arr.first.respond_to?(:call)
      arr.unshift :list
    end
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

  if arr.first.respond_to? :call
    env.instance_eval do
      arr.first.call *arr[1..-1]
    end
  else
    env.send *arr
  end
end

def run str, env = new_env
  evaluate parse(str), env
end

env = new_env

loop do
  p run(gets.chomp, env)
end
