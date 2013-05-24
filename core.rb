class Env
  def initialize sup = nil
    @local_variables = sup ? sup.instance_variable_get("@local_variables").dup : {}
  end

  def env
    self
  end

  [:+, :-, :*, :/].each do |op|
    define_method(op){|*args|args.reduce op}
  end

  def list *args
    args
  end

  def map *args
    args.last.map{|e| args[-2].call e}
  end

  def and *args
    head, *tail = args
    return true if head == nil || head == []
    head = head.first while head.is_a?(Array) && head.size == 1
    boolean?(head) && send(:and, *tail)
  end

  def or *args
    head, *tail = args
    return false if head == nil || head == []
    head = head.first while head.is_a?(Array) && head.size == 1
    boolean?(head) || send(:or, *tail)
  end

  def not arg
    !boolean?(arg)
  end

  def string *args
    args.join
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

  def size list
    list.size
  end

  def atom atom
    atom.is_a? Symbol
  end

  def eq elem1, elem2
    elem1 == elem2
  end
  
  def head x
    x.first
  end

  def tail x
    x[1..-1]
  end

  def cons f, s
    {f: f, s: s}
  end

  def car item
    item[:f]
  end

  def cdr item
    item[:s]
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

  alias display print

  def newline
    puts
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
    "'(#{map(&:inspect).join ' '})"
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

  def inspect
    "'#{to_s}"
  end
end

def parse_token str, vals = []
  val = ""
  is_str = false
  str_char = nil
  loop do
    head = str.shift
    case head
    when '('
      if val =~ /['`]/
        vals << [:quote, parse_token(str)]
        val = ""
      else
        vals << parse_token(str)
      end
    when ' ', ')'
      if is_str
        is_str = !(head == '"')
        val << head
      else
        vals << get_literal(val) unless val.empty?
        val = ""
        return vals if head == ')'
      end
    else
      is_str = !is_str if head == '"'
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

def get_literal token
  if token =~ /\A["'`].+"?\z|\A[-+]?\d+\z|nil|#t|#f/
    case token
    when "#t"
      true
    when "#f"
      false
    when /\A['`]/
      [:quote, get_literal(token[1..-1])]
    else
      eval(token)
    end
  else
    token.to_sym
  end
end

def instruction_dump expr
  if expr.respond_to? :map
    "[#{expr.map(&:to_token).join ","}]"
  else
    expr.to_token
  end
end

def eval_str tokens, env = 'env'
  "evaluate(#{instruction_dump tokens}#{env.nil? ? "" : ", #{env}"})"
end

def evaluate token, env = new_env
  case token
  when Array
    raise "expression should not be blank" if token.empty?
    arr = token
  when Numeric, String, TrueClass, FalseClass, NilClass
    return token
  when Symbol
    return (if env.local_variables?(token) then env[token] else env.method(token) end)
  end
  case arr.first
  when :define
    if arr[1].is_a? Array
      env.class.class_eval %Q{ 
        def #{arr[1].shift} #{arr[1].join ", "}
        #{arr[1].map{|argm| "env[:#{argm}] = #{argm.to_s}"}.join ";"}
        #{eval_str arr[2]}
        end
      }
    else
      env[arr[1]] = evaluate(arr[2], env)
    end
    return
  when :quote
    return arr[1]
  when :lambda
    return env.instance_eval "->(#{arr[1].join ","}){
    env = env.new_stack
    #{arr[1].map{|argm| "env[:#{argm}] = #{argm.to_s}"}.join ";"}
    #{eval_str arr[2]}
    }"
  when :let
    let, var_exprs, expr = arr
    evaluate [[:lambda, var_exprs.map(&:first), expr], * var_exprs.map(&:last)], env
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
  else
    token = arr.first
    if token.respond_to? :call
      env.instance_exec *arr[1..-1].map{|elem| evaluate elem, env.new_stack}, &token
    else
      arr[0] = evaluate arr.first, env.new_stack
      raise "no expression #{arr.first}" if !arr.first.is_a?(Array) && !arr.first.respond_to?(:call)
      evaluate arr, env.new_stack
    end
  end
end

def run str, env = new_env
  expr = parse str
  expr = expr.first
  evaluate expr, env
end
