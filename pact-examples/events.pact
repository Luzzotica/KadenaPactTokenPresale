(namespace "free")

(module events GOV

  (defcap GOV ()
    true
  )

  (defcap EVENT (value:string)
    @event true
  )

  (defun emit (value:string)
    (emit-event (EVENT value))
  )

)