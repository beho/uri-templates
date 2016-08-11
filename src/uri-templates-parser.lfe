(defmodule uri-templates-parser
  (export (parse 1)))

(defun parse [template]
  (let ((ast (grammar:parse template)))
    (case ast
      (_ (when (is_list ast)) ast)
      ((tuple parsed remaining loc)
          (throw `#(error "cannot parse template" ,parsed ,remaining ,loc))))))