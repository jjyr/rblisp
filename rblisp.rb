require_relative 'core'

env = new_env

line = 0
loop do
  line += 1
  print "rblisp :#{line} > "
  p run(gets.chomp, env)
end
