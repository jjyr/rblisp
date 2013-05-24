#some test from
#https://github.com/skandhas/scmrb/blob/master/test.rb

require 'rspec'
require_relative 'core'

describe "rblist" do
  it "shoud parse and run" do
    run("'hello world'").should == "hello world"
    run(%q{'"hello world"'}).should == "\"hello world\""
    run(%q{"'hello world'"}).should == "'hello world'"
    run("(+ 2 2)").should == 4
    run("(+ (* 2 100) (* 1 10))").should == 210
    run("(define x 3)").should == nil
    run("(quote x)").should == :x
    run("exit").class.should == Method
    run("(puts nil)").should == nil

    e = new_env
    run("(define x 5)", e).should == nil
    run("(list x 5 6 7)", e).should == [5,5,6,7]
    run("x", e).should == 5

    run("(quote 'a')").should == 'a'
    run("(quote a)").should == :a
    run("(list 1 2 5 (+ 3 5))").should == [1,2,5,8]
    run("(cond ((atom 6) (+ 2 3)) ((atom (car (list (quote b) 5 9))) (+ 2 2)))").should == 4
    run("((lambda (x) (+ x x)) 5)").should == 10

    e = new_env
    run("(define (f x) (+ x x))", e).should == nil
    run("(f 5)", e).should == 10

    e = new_env
    run("(define x 42)", e).should == nil
    run("(define (f x) (+ x x))", e).should == nil
    run("(f 5)", e).should == 10
    run("x", e).should == 42
    run("(define f2 (lambda (x) (+ x x)))", e).should == nil
    run("(f2 5)", e).should == 10
    run("x", e).should == 42

    e = new_env
    run("(define (f op) (op 2 4))", e).should == nil
    run("(f -)", e).should == -2
    run("(f *)", e).should == 8

    run("((lambda (x) (+ x x)) 5)").should == 10
    run("(and (atom (quote x)) #f)").should == false
    run("(or (atom (quote x)) #f)").should == true
    run("(not (and (and #t #t) (or (and #t #f) #t)))").should == false
    run("(and #t #t #t #f #t)").should == false
    run("(or #f #f #t #f #t)").should == true
    run("(and #t #t)").should == true
    run("(and #f #t)").should == false
    run("(map (lambda (x) (* 2 x)) (list 2 5 4 6))").should == [4, 10, 8, 12]
    run("(string (map (lambda (x) (* 2 x)) (list 2 5 4 6)))").should == "410812"

    e = new_env
    run("(define twice (lambda (x) (* 2 x)))", e).should == nil
    run("(twice 5)", e).should == 10

    e = new_env
    run("(define fact (lambda (n) (cond ((<= n 1) 1) (#t (* n (fact (- n 1)))))))", e).should == nil
    run("(fact 3)", e).should == 6
    run("(fact 50)", e).should == 30414093201713378043612608166064768844377641568960512000000000000

    e = new_env
    run("(define fact (lambda (n) (if (<= n 1) 1 (* n (fact (- n 1))))))", e).should == nil
    run("(fact 3)", e).should == 6
    run("(fact 50)", e).should == 30414093201713378043612608166064768844377641568960512000000000000

    e = new_env
    run("(define abs (lambda (n) ((if (> n 0) + -) 0 n)))", e).should == nil
    run("(list (abs -3) (abs 0) (abs 3))", e).should == [3, 0, 3]
  end
end
