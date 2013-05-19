#some test from
#https://github.com/skandhas/scmrb/blob/master/test.rb

require 'rspec'
require_relative 'core'

describe "rblist" do
  it "shoud parse and run"do
    run("(+ 2 2)").should == 4
    run("(+ (* 2 100) (* 1 10))").should == 210
    run("(define x 3)").should == nil
    run("x").should == :x
    e = new_env
    run("(define x 5)", e).should == nil
    run("(x 5 6 7)", e).should == [5,5,6,7]
    run("x", e).should == 5
    run("(quote 'a')").should == 'a'
    run("(quote a)").should == :a
    run("(1 2 5 (+ 3 5))").should == [1,2,5,8]
    run("(cond ((atom 6) (+ 2 3)) ((atom (car (b 5 9))) (+ 2 2)))").should == 4
    run("((lambda (x) (+ x x)) 5)").should == 10
    e = new_env
    run("(define twice (lambda (x) (* 2 x)))", e).should == nil
    run("(twice 5)", e).should == 10
    e = new_env
    run("(define fact (lambda (n) (if (<= n 1) 1 (* n (fact (- n 1))))))", e).should == nil
    run("(fact 3)", e).should == 6
    run("(fact 50)", e).should == 30414093201713378043612608166064768844377641568960512000000000000
    e = new_env
    run("(define abs (lambda (n) ((if (> n 0) + -) 0 n)))", e).should == nil
    run("(list (abs -3) (abs 0) (abs 3))", e).should == [3, 0, 3]
  end
end
