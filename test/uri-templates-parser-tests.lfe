(defmodule uri-templates-parser-tests
  (behaviour ltest-unit)
  (export all)
  (import (from uri-templates-parser (parse 1))))

(include-lib "ltest/include/ltest-macros.lfe")

(deftest parse-char-literals-only
  (is-equal
    '(#"h" #"t" #"t" #"p" #":" #"/" #"/" #"w" #"w" #"w" #"." #"t" #"e" #"s" #"t" #"." #"c" #"z")
    (parse "http://www.test.cz")))

(deftest parse-pct
  (is-equal
    '(#(pct #"2" #"0"))
    (parse "%20")))
  
(deftest parse-simple-expression
  (is-equal
    '(#(expression none (#(varspec (#"v") ()))))
    (parse "{v}")))
  
(deftest parse-reserved-expression
  (is-equal
    '(#(expression #"+" (#(varspec (#"v") ()))))
    (parse "{+v}")))

(deftest parse-fragment-expression
  (is-equal
    '(#(expression #"#" (#(varspec (#"v") ()))))
    (parse "{#v}")))

(deftest parse-label-expression
  (is-equal
    '(#(expression #"." (#(varspec (#"v") ()))))
    (parse "{.v}")))

(deftest parse-path-segment-expression
  (is-equal
    '(#(expression #"/" (#(varspec (#"v") ()))))
    (parse "{/v}")))

(deftest parse-path-style-parameter-expression
  (is-equal
    '(#(expression #";" (#(varspec (#"v") ()))))
    (parse "{;v}")))

(deftest parse-form-style-query-expression
  (is-equal
    '(#(expression #"?" (#(varspec (#"v") ()))))
    (parse "{?v}")))
                
(deftest parse-form-style-query-continuation-expression
  (is-equal
    '(#(expression #"&" (#(varspec (#"v") ()))))
    (parse "{&v}")))
                
(deftest parse-invalid-operator-expression
  (is-throw
    (parse "{'v}")))

(deftest parse-multiple-vars-expression
  (is-equal
    '(#(expression none (#(varspec (#"v" #"1") ()) #(varspec (#"v" #"2") ()))))
    (parse "{v1,v2}")))

(deftest parse-explode-var-expression
  (is-equal
    '(#(expression none (#(varspec (#"v") #(explode)))))
    (parse "{v*}")))

(deftest parse-prefix-var-expression
  (is-equal
    '(#(expression none (#(varspec (#"v") #(prefix 10)))))
    (parse "{v:10}")))
                