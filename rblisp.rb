require_relative 'core'

env = new_env

loop do
  p run(gets.chomp, env)
end
