rblisp
======

lisp-like interpreter in ruby, just for fun.

######NOTE
1. just for fun.
2. all methods / evaluate / local\_variables delegate to ruby.
3. easy to learn.

######Usage

`ruby rblisp.rb` to start cli

```lisp
(hello world) 
#=> (hello world)

((if (< (size 'hello world') 42) puts 42) "hello world")
#hello world
#=> nil

(exit)
```

######Support
lisp methods: define, lambda, list, eq, quote + / * -, cond, if etc...

ruby Kernel methods: puts, exit, etc...

######Contribute
if you like

fork & feel free to send pull request!
