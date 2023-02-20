(namespace "n_532057688806c2750b8907675929ffb2488e93c0")

(define-keyset "n_532057688806c2750b8907675929ffb2488e93c0.swag-token-ops")

(module swag-token-sale GOV
  ;; -------------------------------
  ;; Governance and Permissions

  (defcap GOV ()
    (enforce-keyset "n_532057688806c2750b8907675929ffb2488e93c0.swag-token-gov")
    (compose-capability (OPS_INTERNAL))
  )

  (defcap OPS ()
    (enforce-keyset "n_532057688806c2750b8907675929ffb2488e93c0.swag-token-ops")
    (compose-capability (OPS_INTERNAL))
  )

  (defcap OPS_INTERNAL ()
    (compose-capability (WHITELIST_UPDATE))
    (compose-capability (RESERVE))
  )

  ;; -------------------------------
  ;; Sale Creation, Updating, and Getting

  (defconst TIER_TYPE_WL:string "WL")
  (defconst TIER_TYPE_PUBLIC:string "PUBLIC")

  (defconst SALE_STATUS_ACTIVE:string "ACTIVE")
  (defconst SALE_STATUS_COMPLETE:string "COMPLETE")
  (defconst SALE_STATUSES:[string] ["ACTIVE" "COMPLETE" "CANCELLED"])

  (defschema tier
    @doc "Stores the start time, end time, tier type (WL, PUBLIC), \
    \ tier-id, cost for this tier (token-per-fungible), \ 
    \ and the limit for each buyer."
    tier-id:string
    tier-type:string
    start-time:time
    end-time:time
    token-per-fungible:decimal
    min-token:decimal
    max-token:decimal
  )

  (defschema sale
    @doc "Defines a sale with a name, \ 
    \ total supply, total-sold, status, fungible, tiers, \
    \ and the fungible and token bank accounts. \
    \ The ID of the sale is the name."
    name:string
    token-name:string
    total-supply:decimal
    total-sold:decimal
    status:string
    fungible:module{fungible-v2}
    fungible-bank-account:string
    fungible-bank-guard:guard
    token:module{fungible-v2}
    token-bank-account:string
    tiers:[object:{tier}]
  )
  (deftable sales:{sale})

  (defcap WITHDRAW ()
    true 
  )

  (defun require-WITHDRAW (sale:string)
    (require-capability (WITHDRAW))
    true
  )

  (defun get-token-bank-guard-for-sale:guard (sale:string)
    (create-user-guard (require-WITHDRAW sale))
  )

  (defun get-token-bank-for-sale:string (sale:string)
    (create-principal (get-token-bank-guard-for-sale sale))
  )

  (defschema in-create-sale 
    name:string
    token-name:string
    total-supply:decimal
    tiers:[object:{tier}]  
  )

  (defun create-sale:string 
    (
      in:object{in-create-sale}
      fungible-bank-guard:guard
      fungible:module{fungible-v2}
      token:module{fungible-v2}
    )  
    @doc "Create a sale with the given paramters."

    (with-capability (OPS)
      (enforce (>= (at "total-supply" in) 0.0) "Total supply must be greater than or equal to 0")
      (validate-tiers (at "tiers" in))

      (token::create-account
        (get-token-bank-for-sale (at "name" in))
        (get-token-bank-guard-for-sale (at "name" in))
      )

      (insert sales (at "name" in)
        (+
          in
          { "fungible": fungible
          , "fungible-bank-guard": fungible-bank-guard
          , "fungible-bank-account": (create-principal fungible-bank-guard)
          , "token": token
          , "token-bank-account": (get-token-bank-for-sale (at "name" in))
          , "status": SALE_STATUS_ACTIVE
          , "total-sold": 0.0
          }
        )
      )
    )
  )

  (defun update-status-for-sale (sale:string status:string)
    @doc "Update the status of the sale."

    (with-capability (OPS)
      (validate-status status)
      (update sales sale { "status": status })
    )
  )

  (defun update-tiers-for-sale (sale:string tiers:[object:{tier}])
    @doc "Update the tiers for the sale."

    (with-capability (OPS)
      (validate-tiers tiers)
      (update sales sale { "tiers": tiers })
    )
  )

  (defun validate-status:bool (status:string)
    (enforce
      (contains status SALE_STATUSES)  
      "Invalid status"
    )
  )

  (defun validate-tiers:bool (tiers:[object:{tier}])
    @doc "Validates the tier start and end time, ensuring they don't overlap \
    \ and that the start is before the end for each tier. \
    \ Validate the tier type (WL or PUBLIC), validate that token-per-fungible is greater than 0, \
    \ and that the min-token is less than the max-token (If not negative)."

    (let*
      (
        (no-overlap
          (lambda (tier:object{tier} other:object{tier})
            ;; If the other is the same as the tier, don't check it
            (if (!= (at "tier-id" tier) (at "tier-id" other))
              (enforce
                (or
                  ;; Start and end of other is before the start of our tier
                  (and?
                    (<= (at "start-time" other))
                    (<= (at "end-time" other))
                    (at "start-time" tier)
                  )
                  ;; Start and end of other is after the end of our tier
                  (and?
                    (>= (at "start-time" other))
                    (>= (at "end-time" other))
                    (at "end-time" tier)
                  )
                )
                "Tiers overlap"
              )
              "Tiers not overlapping"
            )
          )  
        )
        (validate-tier
          (lambda (tier:object{tier})
            ;; Enforce that start is before or equal to end
            ;; and that the tier type is valid
            ;; and that the token-per-fungible is greater or equal to 0
            ;; and that the min-token is less than the max-token (If not negative)
            (enforce
              (<= (at "start-time" tier) (at "end-time" tier))
              "Start must be before end"
            )
            (enforce
              (contains (at "tier-type" tier) [TIER_TYPE_WL TIER_TYPE_PUBLIC])
              "Invalid tier type"
            )
            (enforce
              (>= (at "token-per-fungible" tier) 0.0)
              "Token per fungible must be greater than or equal to 0"
            )
            (if
              (and
                (>= (at "min-token" tier) 0.0)
                (>= (at "max-token" tier) 0.0)  
              )
              (enforce
                (<= (at "min-token" tier) (at "max-token" tier))
                "Min token must be less than or equal to max token"
              )
              []
            )

            (map (no-overlap tier) tiers)
          )  
        )
      )
      (map (validate-tier) tiers)
    )
  )

  (defun get-sale:object{sale} (sale:string)
    @doc "Get the sale object for the given sale name."

    (read sales sale)
  )

  (defun get-current-tier-for-sale:object{tier} (sale:string)
    @doc "Gets the current tier for the sale"
    (with-read sales sale
      { "tiers":= tiers }
      (get-current-tier tiers)  
    )
  )

  (defun get-current-tier:object{tier} (tiers:[object:{tier}])
    @doc "Gets the current tier from the list based on block time"

    (let*
      (
        (now (at "block-time" (chain-data)))
        (filter-tier
          (lambda (tier:object{tier})
            (if (= (at "start-time" tier) (at "end-time" tier))
              (<= (at "start-time" tier) now)
              (and?
                (<= (at "start-time" tier))
                (> (at "end-time" tier))
                now
              )
            )
          )  
        )
        (filtered-tiers (filter (filter-tier) tiers))
      )
      (enforce (> (length filtered-tiers) 0) "No tier is active")
      (at 0 filtered-tiers)
    )
  )

  (defun get-current-sale-price:decimal (sale:string)
    @doc "Get the current sale price for the given sale"

    (at "token-per-fungible" (get-current-tier-for-sale sale))
  )

  (defun get-available-supply-for-sale:decimal (sale:string)
    @doc "Get remaining supply for the given sale"

    (with-read sales sale
      { "total-supply":= total-supply
      , "total-sold":= total-sold
      }
      (- total-supply total-sold)
    )
  )

  (defun get-total-supply-for-sale:decimal (sale:string)
    (at "total-supply" (read sales sale ["total-supply"]))
  )

  (defun get-total-sold-for-sale:decimal (sale:string)
    (at "total-sold" (read sales sale ["total-sold"]))
  )

  (defun get-fungible-bank-for-sale:string (sale:string)
    (at "fungible-bank-account" (read sales sale ["fungible-bank-account"]))
  )

  ;; -------------------------------
  ;; Whitelist Handling

  (defschema whitelisted
    @doc "Store the account of the whitelisted user, the tier-id they are whitelisted for, \
    \ the sale that the tier is in, and the amount of tokens they are allowed to purchase. \
    \ The id is 'sale|tier-id|account'."
    sale:string 
    tier-id:string
    account:string
    purchase-amount:decimal
  )
  (deftable whitelist-table:{whitelisted})

  (defschema tier-whitelist-data
    @doc "A data structure for the whitelist data for a tier. \
    \ Passed into the add whitelist to sale function."
    tier-id:string
    accounts:[string]  
  )

  (defun add-whitelist-to-sale
    (
      sale:string
      tier-data:[object:{tier-whitelist-data}]
    )
    @doc "Requires OPS. Adds the accounts to the whitelist for the given sale and tier."
    (with-capability (OPS)

      (with-read sales sale
        { "tiers":= tiers }
        (validate-whitelist-tier-data tiers tier-data)

        (let
          (
            (handle-tier-data
              (lambda (tier-wl-data:object{tier-whitelist-data})
                (bind tier-wl-data
                  { "tier-id":= tier-id
                  , "accounts":= accounts
                  }
                  (map (add-to-whitelist sale tier-id) accounts)
                )
              )
            )
          )
          (map (handle-tier-data) tier-data)
        )
      )
    )
  )

  (defun add-to-whitelist:string
    (
      sale:string
      tier-id:string
      account:string
    )
    @doc "Requires private OPS. Adds the given account to the whitelist for the given tier."
    (require-capability (OPS))

    (insert whitelist-table (get-whitelist-id sale tier-id account)
      { "sale": sale
      , "tier-id": tier-id
      , "account": account
      , "purchase-amount": 0.0
      }
    )
  )

  (defun is-whitelisted:bool
    (
      sale:string
      tier-id:string
      account:string
    )
    @doc "Returns true if the account is whitelisted for the given tier."
    (with-default-read whitelist-table (get-whitelist-id sale tier-id account)
      { "purchase-amount": -1.0 }
      { "purchase-amount":= purchase-amount }
      (>= purchase-amount 0.0)
    )  
  )

  (defun get-whitelisted-purchase-amount:decimal
    (
      sale:string
      tier-id:string
      account:string
    )
    @doc "Returns the current purchase amount for a whitelisted account in the given tier."
    (with-default-read whitelist-table (get-whitelist-id sale tier-id account)
      { "purchase-amount": -1.0 }
      { "purchase-amount":= purchase-amount }
      purchase-amount
    )  
  )

  (defun get-whitelist-id:string
    (
      sale:string
      tier-id:string
      account:string
    )  
    (concat [sale "|" tier-id "|" account])
  )

  (defcap WHITELIST_UPDATE ()
    true
  )

  (defun update-whitelist-purchase-amount-ops
    (
      sale:string
      tier-id:string
      account:string
      amount:decimal
    )
    @doc "Require OPS. Updates the purchase amount for the given account in the given tier."
    (with-capability (OPS)
      (update-whitelist-purchase-amount sale tier-id account amount)  
    )
  )

  (defun update-whitelist-purchase-amount:string
    (
      sale:string
      tier-id:string
      account:string
      amount:decimal
    )
    @doc "Require Whitelist Update. Updates the purchase amount for the given account in the given tier."
    (require-capability (WHITELIST_UPDATE))

    (update whitelist-table (get-whitelist-id sale tier-id account)
      { "purchase-amount": amount }
    )
  )

  (defun validate-whitelist-tier-data 
    (
      tiers:[object{tier}]
      tier-data:[object{tier-whitelist-data}]
    )
    @doc "Validates the whitelist data against the tiers."
    (let*
      (
        (filter-tier
          (lambda (tier-id:string tier:object{tier})
            (= tier-id (at "tier-id" tier))
          )
        )
        (validate-tier-wl-data
          (lambda (wl-tier-data:object{tier-whitelist-data})
            (let
              (
                (tier (filter (filter-tier (at "tier-id" wl-tier-data)) tiers))
              )  
              (enforce 
                (>= (length tier) 1) 
                (concat ["Couldn't find tier with id: " (at "tier-id" wl-tier-data)])
              )
              (enforce
                (= (at "tier-type" (at 0 tier)) TIER_TYPE_WL)
                "Can't add whitelisted accounts to a non-whitelist tier."
              )
            )
          )
        )
      )
      (map (validate-tier-wl-data) tier-data)
    )
  )

  ;; -------------------------------
  ;; Reserving

  (defschema reservation
    @doc "Stores a reservation for the token in a sale. \
    \ Used to payout tokens onece the sale is complete. \
    \ The ID is the 'sale|account'."
    sale:string
    account:string
    guard:guard
    amount-token:decimal
    amount-token-paid:decimal
    is-paid:bool
  )
  (deftable reservations:{reservation})

  (defcap RESERVE ()
    @doc "Reserve capability for a sale."
    (compose-capability (WHITELIST_UPDATE))
    (compose-capability (WITHDRAW))
    true
  )

  (defcap RESERVE_EVENT 
    (
      sale:string
      account:string
      amount:decimal
    )
    @doc "Reservation can be found using the sale and the account"
    @event true
  )

  (defun reserve:string
    (
      sale:string
      account:string
      amount-fungible:decimal
    )
    @doc "Requires RESERVE. Reserve tokens for the given account."
    (enforce (> amount-fungible 0.0) "Amount must be greater than 0.")

    (with-capability (RESERVE)
      (with-read sales sale
        { "total-supply":= total-supply
        , "total-sold":= total-sold
        , "fungible-bank-account":= fungible-bank-account
        , "status":= status
        , "tiers":= tiers
        , "fungible":= fungible:module{fungible-v2}
        , "token":= token:module{fungible-v2}
        }  
        (enforce (= status SALE_STATUS_ACTIVE) "Sale is not active.")
        (bind (get-current-tier tiers)
          { "tier-id":= tier-id
          , "tier-type":= tier-type
          , "token-per-fungible":= token-per-fungible
          , "min-token":= purchase-min-token
          , "max-token":= purchase-max-token
          }
          (with-default-read reservations (get-reservation-id sale account)
            { "sale": sale
            , "account": account
            , "guard": (at "guard" (fungible::details account))
            , "amount-token": 0.0
            , "amount-token-paid": 0.0
            , "is-paid": false
            }
            { "amount-token":= amount-token-already-purchased
            , "guard":= guard
            }
            (let*
              (
                (amount-token-wl-purchased (get-whitelisted-purchase-amount sale tier-id account))
                (amount-token-purchased (* amount-fungible token-per-fungible))
                (amount-token-wl-purchased-total (+ amount-token-purchased amount-token-wl-purchased))
                (amount-token-purchased-total (+ amount-token-purchased amount-token-already-purchased))
              )
              (enforce
                (<= (+ total-sold amount-token-purchased) total-supply)
                "Purchase amount exceeds total supply"  
              )

              (enforce
                (or
                  (= tier-type TIER_TYPE_PUBLIC)
                  (>= amount-token-wl-purchased 0.0)  
                )
                "Account is not whitelisted"
              )

              (enforce
                (or
                  (< purchase-min-token 0.0) 
                  (<= purchase-min-token amount-token-purchased-total) 
                )  
                "Purchase amount is less than minimum"
              )
              (enforce
                (or
                  (< purchase-max-token 0.0) 
                  (>= purchase-max-token amount-token-purchased-total) 
                )
                "Purchase limit reached"
              )

              (if (= tier-type TIER_TYPE_WL)
                (update-whitelist-purchase-amount sale tier-id account amount-token-wl-purchased-total)
                []
              )

              (fungible::transfer account fungible-bank-account amount-fungible)

              (reserve-internal
                sale
                account
                guard
                amount-token-already-purchased
                amount-token-purchased
                total-sold  
              )
            )
          )
        )
      )
    )
  )

  (defun reserve-internal:bool 
    (
      sale:string
      account:string
      guard:guard
      amount-token-already-purchased:decimal
      amount-token-purchased:decimal
      total-sold:decimal
    )  
    @doc "Requires private RESERVE. Reserves the given amount of tokens for the given account."
    (require-capability (RESERVE))

    (update sales sale
      { "total-sold": (+ total-sold amount-token-purchased) }  
    )

    (if (= amount-token-already-purchased 0.0)
      (insert reservations (get-reservation-id sale account)
        { "sale": sale
        , "account": account
        , "guard": guard
        , "amount-token": amount-token-purchased
        , "amount-token-paid": 0.0
        , "is-paid": false
        }
      )
      (update reservations (get-reservation-id sale account)
        { "amount-token": (+ amount-token-already-purchased amount-token-purchased) 
        , "is-paid": false
        }
      )
    )

    (emit-event
      (RESERVE_EVENT sale account amount-token-purchased)
    )  
    
  )

  (defun get-reservation-id:string (sale:string account:string)
    (concat [sale "|" account])
  )

  (defun get-reservations-for-sale:[object{reservation}] (sale:string)
    (select reservations (where "sale" (= sale)))
  )

  (defun get-unpaid-reservations-for-sale:[object{reservation}] (sale:string)
    (select reservations 
      (and?
        (where "sale" (= sale))
        (where "is-paid" (= false))
      )
    )
  )

  (defun get-reservation-for-account:object{reservation}
    (
      sale:string
      account:string
    )
    @doc "Get the account reservation for the specified sale"

    (with-default-read reservations (get-reservation-id sale account)
      { "sale": sale
      , "account": account
      , "guard": ""
      , "amount-token": 0.0
      , "amount-token-paid": 0.0
      , "is-paid": false
      }
      { "guard":= guard
      , "amount-token":= amount-token
      , "amount-token-paid":= amount-token-paid
      , "is-paid":= is-paid
      }
      { "sale": sale
      , "account": account
      , "guard": guard
      , "amount-token": amount-token
      , "amount-token-paid": amount-token-paid
      , "is-paid": is-paid
      }
    )
  )

  (defun get-total-reserved-for-account:decimal
    (
      sale:string
      account:string
    )  
    @doc "Get the total amount of tokens reserved for the given account for the given sale"

    (at "amount-token" (get-reservation-for-account sale account))
  )

  ;; -------------------------------
  ;; Payouts

  (defun get-payout-accounts-for-sale:[string] (sale:string)
    @doc "Get all accounts that have a payout for the given sale."
    (map
      (at "account")
      (get-unpaid-reservations-for-sale sale)
    )
  )

  (defun payout-reservations:[string]
    (
      sale:string
      accounts:[string]
    )  
    @doc "Requires OPS. Pays out the reservations for the given accounts for the given sale. \
    \ Each account must be in the sale and have a reservation. \
    \ Expects the sale bank to have enough tokens."
    (with-capability (OPS)
      (with-read sales sale
        { "token":= token
        , "token-bank-account":= token-bank-account
        }
        (map
          (payout-reservation-internal sale token token-bank-account )
          accounts
        )
      )
    )
  )

  (defun payout-reservation-internal:string
    (
      sale:string
      token:module{fungible-v2}
      sender:string
      account:string
    )
    @doc "Private WITHDRAW function. Pays out the given account's reservation for the given sale. \
    \ Updates the amount paid for the reservation."
    (require-capability (WITHDRAW))

    (let
      (
        (reservation-id (get-reservation-id sale account))
      )
      (with-read reservations reservation-id
        { "amount-token":= amount-token
        , "amount-token-paid":= amount-token-paid
        , "guard":= guard
        }
        (let
          (
            (transfer-amount
              (floor
                (- amount-token amount-token-paid)  
                (token::precision)
              )  
            )
          )  

          (install-capability
            (token::TRANSFER
              sender
              account
              transfer-amount
            )
          )
          (token::transfer-create sender account guard transfer-amount)

          (update reservations reservation-id
            { "amount-token-paid": amount-token
            , "is-paid": true
            }
          )
        )
      )
    )
  )

  (defun withdraw-from-token-bank:string
    (
      sale:string
      receiver:string
      amount:decimal
    )  
    @doc "Requires OPS. Withdraws the given amount of tokens from the sale's token bank account. \
    \ Expects that the receiver account exists."
    (with-capability (OPS)
      (with-read sales sale
        { "token":= token:module{fungible-v2}
        , "token-bank-account":= token-bank-account
        }  
        (install-capability
          (token::TRANSFER
            token-bank-account
            receiver
            amount
          )
        )
        (token::transfer token-bank-account receiver amount)
      )
    )
  )

)

(if (read-msg "upgrade")
  "Contract upgraded"
  [
    (create-table sales)
    (create-table whitelist-table)
    (create-table reservations)
    (create-sale
      (read-msg "sale")
      (read-keyset "bank-guard")
      coin
      n_532057688806c2750b8907675929ffb2488e93c0.swag-token  
    )
    (add-whitelist-to-sale
        (at "name" (read-msg "sale"))
        (read-msg "tier-data")
    )
  ]
)