(defmodule uri-templates
  (export all)
  (import (from uri-templates-parser (parse 1))))

(include-file "include/records.lfe")

;; use maps https://gist.github.com/BinaryMuse/bb9f2cbf692e6cfa4841
(defun expand [template vars]
  (let (((match-uri-template fragments fragments) (parse template)))
    (flet ((fragment-reducer [fragment acc]
             (let ((fragment-expansion (expand-fragment fragment vars)))
               (++ acc fragment-expansion))))
      (lists:foldl #'fragment-reducer/2 "" fragments))))

(defun expand-fragment
  ([(= (tuple expression _ _) expr) vars]
      (expand-expression expr vars))
  ([(tuple 'pct h1 h2) _]
      `(%"%" ,h1 ,h2))
  ([l _] l))

(defun expand-expression [expression vars]
  (let* (((tuple 'expression operator varspecs) expression)
         (expander (var-expander operator)))
    (flet ((expression-reducer [varspec acc]
             (let* (((tuple 'varspec varname) varspec)
                    (value (-var-value varname vars))
                    (is-first (=:= acc ""))
                    (expansion (expand-varspec expander varspec value is-first)))
                (++ acc expansion))))
      (lists:foldl #'expression-reducer/2 "" varspecs))))


(defun expand-varspec [expander varspec value is-first]
  (let (((tuple 'varspec varname) varspec))
    (funcall expander varname value is-first)))

(defun -var-value [varname vars]
  (maps:get varname vars 'none))

(defun var-expander [operator]
    (case operator
      ('none #'expand-simple-expression-var/3)
      (#"+" #'expand-reserved-expression-var/3)
      (#"#" #'expand-fragment-expression-var/3)
      (#"." #'expand-label-expression-var/3)
      (#"/" #'expand-path-segment-expression-var/3)
      (#";" #'expand-path-style-parameter-expression-var/3)
      (#"?" #'expand-form-style-query-expression-var/3)
      (#"&" #'expand-form-style-query-continuation-expression-var/3))) 

(defun expand-simple-expression-var
  ([_ 'none _] 
      #"")
   ([_ value 'true] 
      value)
   ([_ value 'false] 
      `(#"," ,value)))

;;; TODO follow spec 
(defun expand-reserved-expression-var
  ([_ 'none _] 
      #"")
   ([_ value 'true] 
      value)
   ([_ value 'false] 
      `(#"," ,value)))

(defun expand-fragment-expression-var
  ([_ 'none _]
      #"")
  ([_ value 'true]
      `(#"#" ,value))
  ([_ value 'false]
      `(#"," ,value)))

(defun expand-label-expression-var
  ([_ 'none _]
      #"")
  ([_ value _]
      `(#"." ,value)))

;; TODO encode / in value
(defun expand-path-segment-expression-var
  ([_ 'none _]
      #"")
  ([_ value _]
      `(#"/" ,value)))

(defun expand-path-style-parameter-expression-var
  ([_ 'none _]
      #"")
  ([varname #"" _]
      `(#";" ,varname))
  ([varname value _]
      `(#";" ,varname #"=" ,value)))

(defun expand-form-style-query-expression-var
  ([_ 'none _]
      #"")
  ([varname value 'true]
      `(#"?" ,varname #"=" ,value))
  ([varname value 'false]
      `(#"&" ,varname #"=" ,value)))

(defun expand-form-style-query-continuation-expression-var
  ([_ 'none _]
      "")
  ([varname value _]
      `(#"&" ,varname #"=" ,value)))
