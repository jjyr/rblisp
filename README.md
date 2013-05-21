rblisp
======

lisp-like interpreter in ruby.

##NOTE
1. For study, just enough.
2. all methods / evaluate / local\_variables delegate to ruby.
3. easy to learn.

##Usage

`ruby rblisp.rb` to start cli

```lisp
(hello world) 
#=> (hello world)

((if (< (size "hello world") 42) puts 42) "hello world")
#hello world
#=> nil

(exit)
```

or

`ruby rblisp.rb test.lisp` to run file

##Support Methods
lisp methods: define, lambda, list, eq, map, quote + / * -, cond, if, and, or, not, size, >, <, >=, <= etc...

ruby Kernel methods: puts, exit, etc...

##LICENSE
Copyright (c) 2013 jjy

MIT License

##Contribute
if you like

fork & feel free to send pull request!
