(defrecord uri-template
  fragments '())

(defrecord literal
  value)

(defrecord expression
  operator
  (varspecs '()))

(defrecord varspec
  varname
  (modifier 'undefined)
  (modifier-arg 'undefined))