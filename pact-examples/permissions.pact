(namespace "free")

(define-keyset "free.gov")
(define-keyset "free.ops")

(module permissions GOV

  ;; -------------------------------
  ;; Governance and Permissions

  (defcap GOV ()
    (enforce-keyset "free.gov")
    (compose-capability (INTERNAL))
  )

  (defcap OPS ()
    (enforce-keyset "free.ops")
    (compose-capability (INTERNAL))
  )

  (defcap INTERNAL ()
    true
  )

  (defun with-ops ()
    (with-capability (OPS)
      "Ops granted!"
    )
  )

  (defun withdraw-ops (amount:decimal)
    (with-capability (OPS)
      (withdraw amount)
    )
  )

  (defcap PURCHASE ()
    (compose-capability (INTERNAL))
  )

  (defun purchase-tokens (amount:decimal)
    (with-capability (PURCHASE)
      ;; Transfer the KDA from the purchaser to me
      ;; THEN withdraw the tokens to the purchaser
      (withdraw amount)
    )
  )

  (defun withdraw (amount:decimal)
    (require-capability (INTERNAL))
    (format "Withdrew {} tokens" [amount])
  )

)