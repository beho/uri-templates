(defmodule uri-templates-tests
  (behaviour ltest-unit)
  (export all)
  (import (from uri-templates (expand-simple-expression-var 3)
                              (expand-reserved-expression-var 3)
                              (expand-fragment-expression-var 3)
                              (expand-label-expression-var 3)
                              (expand-path-segment-expression-var 3)
                              (expand-path-style-parameter-expression-var 3)
                              (expand-form-style-query-expression-var 3)
                              (expand-form-style-query-continuation-expression-var 3))
          (from erlang (iolist_to_binary 1))))

(include-lib "ltest/include/ltest-macros.lfe")

(deftest expand-simple-expression-var
  (is-equal 
    #""
    (iolist_to_binary (expand-simple-expression-var #"var" 'none 'true)))
  (is-equal
    #""
    (iolist_to_binary (expand-simple-expression-var #"var" 'none 'false)))
  (is-equal 
    #"value" 
    (iolist_to_binary (expand-simple-expression-var #"var" #"value" 'true)))
  (is-equal
    #",value"
    (iolist_to_binary (expand-simple-expression-var #"var" #"value" 'false))))

(deftest expand-reserved-expression-var
  (is-equal 
    #"" 
    (iolist_to_binary (expand-reserved-expression-var #"var" 'none 'true)))
  (is-equal
    #""
    (iolist_to_binary (expand-reserved-expression-var #"var" 'none 'false)))
  (is-equal 
    #"value" 
    (iolist_to_binary (expand-reserved-expression-var #"var" #"value" 'true)))
  (is-equal
    #",value"
    (iolist_to_binary (expand-reserved-expression-var #"var" #"value" 'false))))

(deftest expand-fragment-expression-var
  (is-equal
    #""
    (iolist_to_binary (expand-fragment-expression-var #"var" 'none 'true)))
  (is-equal
    #""
    (iolist_to_binary (expand-fragment-expression-var #"var" 'none 'false)))
  (is-equal
    #"#value"
    (iolist_to_binary (expand-fragment-expression-var #"var" #"value" 'true)))
  (is-equal
    #",value"
    (iolist_to_binary (expand-fragment-expression-var #"var" #"value" 'false))))

(deftest expand-label-expression-var
  (is-equal
    #""
    (iolist_to_binary (expand-label-expression-var #"var" 'none 'true)))
  (is-equal
    #""
    (iolist_to_binary (expand-label-expression-var #"var" 'none 'false)))
  (is-equal
    #".value"
    (iolist_to_binary (expand-label-expression-var #"var" #"value" 'true)))
  (is-equal
    #".value"
    (iolist_to_binary (expand-label-expression-var #"var" #"value" 'false))))

(deftest expand-path-segment-expression-var
  (is-equal
    #""
    (iolist_to_binary (expand-path-segment-expression-var #"var" 'none 'true)))
  (is-equal
    #""
    (iolist_to_binary (expand-path-segment-expression-var #"var" 'none 'false)))
  (is-equal
    #"/value"
    (iolist_to_binary (expand-path-segment-expression-var #"var" #"value" 'true)))
  (is-equal
    #"/value"
    (iolist_to_binary (expand-path-segment-expression-var #"var" #"value" 'false))))

(deftest expand-path-style-parameter-expression-var
  (is-equal
    #""
    (iolist_to_binary (expand-path-style-parameter-expression-var #"var" 'none 'true)))
  (is-equal
    #""
    (iolist_to_binary (expand-path-style-parameter-expression-var #"var" 'none 'false)))
  (is-equal
    #";var"
    (iolist_to_binary (expand-path-style-parameter-expression-var #"var" #"" 'true)))
  (is-equal
    #";var"
    (iolist_to_binary (expand-path-style-parameter-expression-var #"var" #"" 'false)))
  (is-equal
    #";var=value"
    (iolist_to_binary (expand-path-style-parameter-expression-var #"var" #"value" 'true)))
  (is-equal
    #";var=value"
    (iolist_to_binary (expand-path-style-parameter-expression-var #"var" #"value" 'false))))

(deftest expand-form-style-query-expression-var
  (is-equal
    #""
    (iolist_to_binary (expand-form-style-query-expression-var #"var" 'none 'true)))
  (is-equal
    #""
    (iolist_to_binary (expand-form-style-query-expression-var #"var" 'none 'false)))
  (is-equal
    #"?var="
    (iolist_to_binary (expand-form-style-query-expression-var #"var" #"" 'true)))
  (is-equal
    #"&var="
    (iolist_to_binary (expand-form-style-query-expression-var #"var" #"" 'false)))
  (is-equal
    #"?var=value"
    (iolist_to_binary (expand-form-style-query-expression-var #"var" #"value" 'true)))
  (is-equal
    #"&var=value"
    (iolist_to_binary (expand-form-style-query-expression-var #"var" #"value" 'false))))

(deftest expand-form-style-query-continuation-expression-var
  (is-equal
    #""
    (iolist_to_binary (expand-form-style-query-continuation-expression-var #"var" 'none 'true)))
  (is-equal
    #""
    (iolist_to_binary (expand-form-style-query-continuation-expression-var #"var" 'none 'false)))
  (is-equal
    #"&var="
    (iolist_to_binary (expand-form-style-query-continuation-expression-var #"var" #"" 'true)))
  (is-equal
    #"&var="
    (iolist_to_binary (expand-form-style-query-continuation-expression-var #"var" #"" 'false)))
  (is-equal
    #"&var=value"
    (iolist_to_binary (expand-form-style-query-continuation-expression-var #"var" #"value" 'true)))
  (is-equal
    #"&var=value"
    (iolist_to_binary (expand-form-style-query-continuation-expression-var #"var" #"value" 'false))))

