rblisp
======

lisp / scheme interpreter in ruby.

##NOTE
1. implements in ruby, use many ruby tricks.
2. all methods / evaluate / local\_variables delegate to ruby.
3. easy to understand.

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
lisp methods: 
>let, define, lambda, list, eq, map, quote ` or ' , + / * -, cond, if, and, or, not, size, head, tail, car, cdr, cons, display, newline, >, <, >=, <= etc...

ruby Kernel methods:
>puts, exit, etc...

##LICENSE
Copyright (c) 2013 jjy

MIT License

##Contribute
fork & feel free to send pull requests!
