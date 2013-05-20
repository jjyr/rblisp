require 'pry'
require 'pry-nav'

class Env
  def initialize sup = nil
    @local_variables = sup ? sup.instance_variable_get("@local_variables").dup : {}
  end

  [:+, :-, :*, :/].each do |op|
    define_method(op){|*args|args.reduce op}
  end

  def list *args
    args
  end

  def [] key
    @local_variables[key]
  end

  def []= key, value
    @local_variables[key] = value
  end

  def local_variables? key
    @local_variables.has_key? key
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
    x[1..-1]
  end

  def cons h, list
    list.unshift h
  end

  def new_stack
    self.class.new self
  end

  def < x1, x2
    x1 < x2
  end

  def > x1, x2
    x1 > x2
  end

  def <= x1, x2
    !send(:>, x1, x2)
  end

  def >= x1, x2
    !send(:<, x1, x2)
  end
end

def new_env_class
  Class.new Env
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

[TrueClass, FalseClass, NilClass].each do |klass|
  klass.class_eval "def to_token; self; end"
end

class String
  alias to_token inspect
end

class Fixnum
  alias to_token to_s
end

class Bignum
  alias to_token to_s
end

class Float
  alias to_token to_s
end

class Symbol
  def to_token
    ":#{self}"
  end
  alias inspect to_s
end

def parse_token str, vals = []
  val = ""
  loop do
    head = str.shift
    case head
    when '('
      vals << parse_token(str)
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
  parse_token str
rescue StandardError => e
  raise "parse error: #{e.message}"
end

def boolean? token
  case token
  when true, :"#t"
    true
  when false, :"#f"
    false
  else
    raise "#{token} is not boolean!"
  end
end

def is_literal? token, env = new_env
  token.is_a?(String) || token.is_a?(Numeric) || token.is_a?(Symbol) && !env.respond_to?(token, true)
end

def instruction_dump expr
  if expr.respond_to? :map
    "[#{expr.map(&:to_token).join ","}]"
  else
    expr
  end
end

def eval_str tokens, env = 'env'
  "evaluate(#{instruction_dump tokens}#{env.nil? ? "" : ", #{env}"})"
end

def evaluate token, env = new_env
  case token
  when Array
    arr = token
  when Numeric, String, TrueClass, FalseClass, NilClass
    return token
  when Symbol
    return env.local_variables?(token) ? env[token] : token
  end
  case arr.first
  when :define
    if arr[1].is_a? Array
      env.class.class_eval %Q{ 
        def #{arr[1].shift} #{arr[1].join ", "}
        #{arr[2..-1].map{|expr| eval_str expr}.join ";"}
        end
      }
    else
      env[arr[1]] = evaluate(arr[2], env)
    end
    return
  when :lambda
    return env.instance_eval "->(#{arr[1].join ","}){
    #{arr[1].map{|argm| "env[:#{argm}] = #{argm.to_s}"}.join ";"}
    #{eval_str arr[2], "env"}
    }"
  when :if
    _if, cond, t_tokens, el_token = arr
    evaluate [:cond, [cond, t_tokens], [true, el_token]], env.new_stack
  when :cond
    case arr[1]
    when Array
      condition, tokens = arr[1]
      return evaluate([env.instance_eval("->(){
      if boolean? #{eval_str condition}
      #{eval_str tokens}
      else
      #{arr.delete_at(1);eval_str arr}
      end
      }")], env.new_stack)
    when nil
      return
    else 
      raise "parse error"
    end
  when Array
    arr.unshift :list if arr.size == 1 && arr.first.is_a?(Array)
    arr[0] = evaluate arr.first, env.new_stack
    evaluate arr, env.new_stack
  else
    token = arr.first
    if token.is_a?(Symbol) && env.respond_to?(token, true)
      env.send arr.first, *arr[1..-1].map{|elem| evaluate elem, env.new_stack}
    elsif token.respond_to? :call
      env.instance_eval do
        token.call *arr[1..-1].map{|elem| evaluate elem, env.new_stack}
      end
    else
      unless token.is_a?(Symbol) && env.local_variables?(token)
        arr.unshift :list 
        evaluate arr, env
      else
        arr[0] = evaluate arr.first, env.new_stack
        evaluate arr, env.new_stack
      end
    end
  end
end

def run str, env = new_env
  expr = parse str
  expr = expr.first
  evaluate expr, env
end
