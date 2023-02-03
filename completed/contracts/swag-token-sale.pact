(namespace "free")

(define-keyset "free.swag-token-ops")

(module swag-token-sale GOV

  ;; -------------------------------
  ;; Governance and Permissions

  (defcap GOV ()
    (enforce-keyset "free.swag-token-gov")
    (compose-capability (OPS_INTERNAL))
  )

  (defcap OPS ()
    (enforce-keyset "free.swag-token-ops")
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
  (defconst SALE_STATUSES:[string] ["ACTIVE" "CANCELED" "COMPLETE"])

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

  (defschema sale ;; ID is name
    @doc "Defines a sale with a name, \ 
    \ total supply, total-sold, status, fungible, and tiers. \
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

  (defun require-WITHDRAW:bool (sale:string)
    (require-capability (WITHDRAW))
    true
  )

  (defun get-token-bank-guard-for-sale:guard (sale:string)
    @doc "Creates a guard that is used for the token bank of the sale"
    (create-user-guard (require-WITHDRAW sale))
  )

  (defun get-token-bank-for-sale:string (sale:string)
    (create-principal (get-token-bank-guard-for-sale sale))
  )

  (defschema in-create-sale
    @doc "A data structure for the sale data"
    name:string
    token-name:string
    total-supply:decimal
    tiers:[object:{tier}]
  )

  (defun create-sale:string 
    (
      in:object
      fungible-bank-guard:guard
      fungible:module{fungible-v2}
      token:module{fungible-v2}
    )
    @doc "Create sale with parameters."
    
    (with-capability (OPS)
      (enforce (> (at "total-supply" in) 0.0) "Token total supply must be positive")
      (validate-tiers (at "tiers" in))

      (token::create-account
        (get-token-bank-for-sale (at "name" in))
        (get-token-bank-guard-for-sale (at "name" in))
      )

      (insert sales (at "name" in)
        (+
          in
          { "fungible-bank-guard": fungible-bank-guard
          , "fungible-bank-account": (create-principal fungible-bank-guard)
          , "token-bank-account": (get-token-bank-for-sale (at "name" in))
          , "status": "ACTIVE"
          , "fungible": fungible
          , "token": token
          , "total-sold": 0.0
          }
        )
      )
    )
  )

  (defun update-sale-status:string (sale:string status:string)
    @doc "End sale by setting its status"
    (with-capability (OPS)
      (validate-status status)
      (update sales sale 
        { "status": status }
      )
    )
  )

  (defun update-sale-tiers 
    (
      sale:string 
      tiers:[object:{tier}]
    )
    @doc "Updates the tiers of the given sale"
    (with-capability (OPS)
      (validate-tiers tiers)
      (update sales sale
        { "tiers": tiers }
      )
    )
  )

  (defun validate-status:bool (status:string)
    @doc "Validates the status is one of the valid statuses"
    (enforce 
      (contains status SALE_STATUSES)
      "Invalid status"
    )
    true
  )

  (defun validate-tiers:bool (tiers:[object:{tier}])
    @doc "Validates the tier start and end time, ensuring they don't overlap \
    \ and that start is before end for each."
    (let*
      (
        (no-overlap
          (lambda (tier:object{tier} other:object{tier})
            ;; If the other is the same as the tier, don't check it
            (if (!= (at "tier-id" tier) (at "tier-id" other))
              (enforce 
                (or
                  ;; Start and end of other is before start of tier
                  (and? 
                    (<= (at "start-time" other))
                    (<= (at "end-time" other)) 
                    (at "start-time" tier)
                  )
                  ;; Start and end of other is after end of tier
                  (and?
                    (>= (at "end-time" other))
                    (>= (at "start-time" other)) 
                    (at "end-time" tier)
                  )
                )
                "Tiers overlap"
              )
              []
            )
          )
        )
        (validate-tier 
          (lambda (tier:object{tier})
            ;; Enforce start time is before end time, 
            ;; and that the tier type is valid,
            ;; and that the token-per-fungible is positive
            (enforce
              (<= (at "start-time" tier) (at "end-time" tier)) 
              "Start must be before end"
            )
            (enforce
              (or 
                (= (at "tier-type" tier) TIER_TYPE_WL)
                (= (at "tier-type" tier) TIER_TYPE_PUBLIC)
              )
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
                "min-token must be less than or equal to max-token"
              )
              []
            )
            
            ;; Loop through all the tiers and ensure they don't overlap
            (map (no-overlap tier) tiers)
          )
        )
      )
      (map (validate-tier) tiers)
    )
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
              (>= now (at "start-time" tier))  
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
      (enforce (> (length filtered-tiers) 0) (format "No tier found: {}" [now]))
      (at 0 filtered-tiers)
    )
  )

  (defun get-sale:object{sale} (sale:string)
    @doc "Returns sale object"

    (read sales sale)
  )

  (defun get-current-sale-price:decimal (sale:string)
    @doc "Gets the token amount per kda for the given sale"

    (at "token-per-fungible" (get-current-tier-for-sale sale))
  )

  (defun get-available-supply-for-sale:decimal (sale:string)
    @doc "Get remaining token supply in specified sale"

    (with-read sales sale 
      { "total-supply" := total-supply
      , "total-sold" := total-sold
      }
      (- total-supply total-sold)
    )
  )

  (defun get-total-supply-for-sale:decimal (sale:string)
    (at "total-supply" (read sales sale ["total-supply"]))
  )

  (defun get-total-sold-for-sale:decimal (sale:string)
    @doc "Get token supply of specified sale"

    (at "total-sold" (read sales sale ["total-sold"]))
  )

  (defun get-fungible-bank-for-sale:string (sale:string)
    (at "fungible-bank-account" (read sales sale ["fungible-bank-account"]))
  )

  ;; -------------------------------
  ;; Whitelist Handling

  (defschema whitelisted
    @doc "Stores the account of the whitelisted user, the tier-id, \
    \ and amount they have purchaesed. The id is 'sale|tier-id|account'."
    sale:string
    tier-id:string
    account:string
    purchase-amount:decimal
  )
  (deftable whitelist-table:{whitelisted})

  (defschema tier-whitelist-data
    @doc "A data structure for the whitelist data for a tier"
    tier-id:string
    accounts:[string]
  )

  (defun add-whitelist-to-sale
    (
      sale:string 
      tier-data:[object{tier-whitelist-data}]
    )
    @doc "Requires OPS. Adds the accounts to the whitelist for the given tier."
    (with-read sales sale
      { "tiers":= tiers }
      (validate-whitelist-tier-data tiers tier-data)

      (with-capability (OPS)
        (let
          (
            (handle-tier-data 
              (lambda (tier-data:object{tier-whitelist-data})
                (bind tier-data
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
    @doc "Requires private OPS. Adds the account to the whitelist for the given tier."
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
      (!= purchase-amount -1.0)
    )
  )

  (defun get-whitelist-purchase-amount:decimal
    (
      sale:string 
      tier-id:string 
      account:string
    )
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

  (defun update-whitelist-purchase-amount-ops:string 
    (
      sale:string
      tier-id:string
      account:string
      purchase-amount:decimal
    )
    @doc "Requires OPS. Updates the whitelist purchase amount for the given account."
    (with-capability (OPS)
      (update-whitelist-purchase-amount sale tier-id account purchase-amount)
    )
  )

  (defun update-whitelist-purchase-amount 
    (
      sale:string 
      tier-id:string 
      account:string 
      amount:decimal
    )
    @doc "Requires Whitelist Update. Updates the mint count for the given account in the whitelist."
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
          (lambda (tier-id tier:object{tier})
            (= tier-id (at "tier-id" tier))
          )  
        )
        (validate-tier-wl-data
          (lambda (wl-tier-data:object{tier-whitelist-data})
            ;; Validate that the tier-id is valid
            (let
              (
                (tier (filter (filter-tier (at "tier-id" wl-tier-data)) tiers))
              )
              (enforce 
                (!= (length tier) 0) 
                (concat ["Couldn't find tier with id: " (at "tier-id" wl-tier-data)])
              )
              (enforce
                (= (at "tier-type" (at 0 tier)) "WL")
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

  (defschema reservation ;; ID is sale|account
    @doc "Stores a reservation for the toks, which is used to pay out the \
    \ tokens once the sale is complete."
    sale:string
    account:string
    guard:guard
    amount-token:decimal
    amount-token-paid:decimal
    is-paid:bool
  )
  (deftable reservations:{reservation})

  (defcap RESERVE ()
    @doc "Reserve event for token reservation"
    (compose-capability (WHITELIST_UPDATE))
    (compose-capability (WITHDRAW))
    @event
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
    @doc "Reserve tokens for the given account."
    (enforce (> amount-fungible 0.0) "Amount must be greater than 0")

    (with-capability (RESERVE)
      (with-read sales sale 
        { "total-supply":= total-supply
        , "total-sold":= total-sold
        , "fungible-bank-account":= bank-account 
        , "fungible-bank-guard":= fungible-bank-guard
        , "status":= status
        , "tiers":= tiers
        , "fungible":= fungible:module{fungible-v2}
        , "token":= token:module{fungible-v2}
        }
        (enforce (= status SALE_STATUS_ACTIVE) "Sale is not active")
        (bind (get-current-tier tiers) 
          { "min-token":= purchase-min-token
          , "max-token":= purchase-max-token
          , "token-per-fungible":= token-per-fungible
          , "tier-id":= tier-id
          , "tier-type":= tier-type
          }
          (with-default-read reservations (get-reservation-id sale account)
            { "sale": sale
            , "account": account
            , "guard": (at "guard" (fungible::details account)) 
            , "amount-token": 0.0
            , "amount-token-paid": 0.0
            , "is-paid": false
            }
            { "amount-token":= curr-amount-token-purchased
            , "guard":= guard
            }
            (let*
              (
                (amount-token-wl-purchased (get-whitelist-purchase-amount sale tier-id account))
                (amount-token-purchased (* amount-fungible token-per-fungible))
                (amount-token-wl-purchased-total (+ amount-token-wl-purchased amount-token-purchased))
                (amount-token-purchased-total (+ amount-token-purchased curr-amount-token-purchased))
              )
              ;; Make sure that the amount being purchased isn't over the total supply
              (enforce 
                (<= (+ total-sold amount-token-purchased) total-supply)
                "Purchase amount exceeds total supply"
              )

              ;; If the tier is public, anyone can purchase
              ;; If the curr-purchase-amount is -1, the account is not whitelisted
              (enforce 
                (or 
                  (= tier-type TIER_TYPE_PUBLIC)
                  (!= amount-token-wl-purchased -1.0)
                )
                "Account is not whitelisted"
              )

              ;; If the min or max is negative, we can ignore them
              ;; Otherwise, enforce them
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
  
              ;; If the tier is whitelist, the update the wl purchase amount
              (if (= tier-type TIER_TYPE_WL)
                (update-whitelist-purchase-amount sale tier-id account amount-token-wl-purchased-total)
                []
              )
    
              (fungible::transfer-create 
                account 
                bank-account 
                fungible-bank-guard 
                amount-fungible
              )
              
              (reserve-internal 
                sale 
                account 
                guard
                curr-amount-token-purchased
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
      amount-token:decimal
      amount-token-purchased:decimal
      total-sold:decimal
    )
    (require-capability (RESERVE))

    (update sales sale
      { "total-sold": (+ total-sold amount-token-purchased) }
    )
    ;; If the amount is 0, we need to insert a new reservation
    (if (= amount-token 0.0)
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
        { "amount-token": (+ amount-token amount-token-purchased)
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
    @doc "Get all reservations for specified sale"

    (select reservations (where 'sale (= sale)))
  )

  (defun get-reservation-for-account:object{reservation} 
    (
      sale:string 
      account:string
    )
    @doc "Get all account reservations for specified sale"
    
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

  (defun get-unpaid-reservations-for-sale (sale:string)
    @doc "Get all unpaid reservations for specified sale"

    (select reservations 
      (and? 
        (where 'sale (= sale))
        (where 'is-paid (= false))
      )
    )
  )

  (defun get-total-reserved-for-account:decimal 
    (
      sale:string 
      account:string
    )
    @doc "Get total token reserved for account in specified sale"

    (at "amount-token" (get-reservation-for-account sale account))
  )

  ;; -------------------------------
  ;; Payouts

  (defun payout-reservations:[string]
    (
      sale:string 
      accounts:[string]
    )
    @doc "Requires OPS. Pays out a reservations for the given sale \
    \ to the provided list of accounts. Each account must be in the sale \
    \ and have a reservation. Expects the sale bank to have enough tokens."
    (with-capability (OPS)
      (with-read sales sale
        { "token":= token }
        (map 
          (payout-reservation-internal 
            sale 
            token 
            (get-token-bank-for-sale sale)
          )
          accounts
        )
      )
    )
  )

  (defun payout-reservation-internal:[string]
    (
      sale:string
      token:module{fungible-v2}
      sender:string
      account:string
    )
    @doc "Private function. Pays the given amount of tokens to the \
    \ given account. Updates the amount paid for the reservation."
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
            (trans-amount 
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
              trans-amount
            )
          )
          (token::transfer-create 
            sender 
            account 
            guard 
            trans-amount
          )
  
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
    @doc "Requires Ops. Withdraws the given amount of tokens from \
    \ the sale token bank to the given receiver. \
    \ Expects the sale bank to have enough tokens."
    (with-capability (OPS)
      (with-read sales sale
        { "token":= token:module{fungible-v2}
        , "token-bank-account":= bank-account
        }
        (install-capability 
          (token::TRANSFER 
            bank-account
            receiver
            amount
          )
        )
        (token::transfer
          bank-account
          receiver 
          amount
        )
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
      free.swag-token
    )
    (add-whitelist-to-sale 
      (read-msg "sale-name")
      (read-msg "tier-data")
    )
  ]
)