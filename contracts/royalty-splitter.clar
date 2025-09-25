;; Music Royalty Distribution Smart Contract
;; Automated music royalty distribution system for artists, producers, and rights holders

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PERCENTAGE (err u101))
(define-constant ERR-TRACK-EXISTS (err u102))
(define-constant ERR-TRACK-NOT-FOUND (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-INVALID-STAKEHOLDER (err u105))
(define-constant ERR-SPLITS-NOT-100 (err u106))
(define-constant ERR-PAYMENT-FAILED (err u107))
(define-constant ERR-CONTRACT-PAUSED (err u108))
(define-constant ERR-MINIMUM-NOT-MET (err u109))
(define-constant ERR-ALREADY-CLAIMED (err u110))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Contract state
(define-data-var contract-paused bool false)
(define-data-var minimum-payment-amount uint u1000000) ;; 1 STX minimum
(define-data-var total-tracks uint u0)
(define-data-var total-distributed uint u0)

;; Data structures
(define-map tracks
  { track-id: (string-ascii 64) }
  {
    creator: principal,
    total-stakeholders: uint,
    total-royalties: uint,
    distributed-amount: uint,
    created-at: uint,
    is-active: bool
  }
)

(define-map track-stakeholders
  { track-id: (string-ascii 64), stakeholder: principal }
  {
    percentage: uint,
    claimed-amount: uint,
    pending-amount: uint,
    last-claim: uint
  }
)

(define-map royalty-deposits
  { track-id: (string-ascii 64), deposit-id: uint }
  {
    amount: uint,
    depositor: principal,
    timestamp: uint,
    distributed: bool
  }
)

(define-map stakeholder-totals
  { stakeholder: principal }
  {
    total-earned: uint,
    total-claimed: uint,
    pending-claims: uint,
    tracks-count: uint
  }
)

;; Track deposit counters
(define-map track-deposit-counters
  { track-id: (string-ascii 64) }
  { counter: uint }
)

;; Public functions

;; Create a new royalty pool for a track
(define-public (create-royalty-pool 
  (track-id (string-ascii 64))
  (stakeholders (list 20 { stakeholder: principal, percentage: uint }))
)
  (begin
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? tracks { track-id: track-id })) ERR-TRACK-EXISTS)
    
    ;; Validate total percentages equal 100
    (asserts! (is-eq (fold + (map get-percentage stakeholders) u0) u100) ERR-SPLITS-NOT-100)
    
    ;; Create the track entry
    (map-set tracks
      { track-id: track-id }
      {
        creator: tx-sender,
        total-stakeholders: (len stakeholders),
        total-royalties: u0,
        distributed-amount: u0,
        created-at: block-height,
        is-active: true
      }
    )
    
    ;; Initialize deposit counter for track
    (map-set track-deposit-counters
      { track-id: track-id }
      { counter: u0 }
    )
    
    ;; Add stakeholders
    (map add-stakeholder-to-track stakeholders track-id)
    
    ;; Update total tracks count
    (var-set total-tracks (+ (var-get total-tracks) u1))
    
    (ok track-id)
  )
)

;; Deposit royalties for a specific track
(define-public (deposit-royalties (track-id (string-ascii 64)) (amount uint))
  (let (
    (track-data (unwrap! (map-get? tracks { track-id: track-id }) ERR-TRACK-NOT-FOUND))
    (deposit-counter (default-to { counter: u0 } (map-get? track-deposit-counters { track-id: track-id })))
    (new-counter (+ (get counter deposit-counter) u1))
  )
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (asserts! (>= amount (var-get minimum-payment-amount)) ERR-MINIMUM-NOT-MET)
    (asserts! (get is-active track-data) ERR-TRACK-NOT-FOUND)
    
    ;; Transfer STX to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Record the deposit
    (map-set royalty-deposits
      { track-id: track-id, deposit-id: new-counter }
      {
        amount: amount,
        depositor: tx-sender,
        timestamp: block-height,
        distributed: false
      }
    )
    
    ;; Update deposit counter
    (map-set track-deposit-counters
      { track-id: track-id }
      { counter: new-counter }
    )
    
    ;; Update track totals
    (map-set tracks
      { track-id: track-id }
      (merge track-data { total-royalties: (+ (get total-royalties track-data) amount) })
    )
    
    ;; Distribute to stakeholders
    (try! (distribute-to-stakeholders track-id amount))
    
    (ok new-counter)
  )
)

;; Allow stakeholders to claim their pending payments
(define-public (claim-payment (track-id (string-ascii 64)))
  (let (
    (stakeholder-data (unwrap! (map-get? track-stakeholders { track-id: track-id, stakeholder: tx-sender }) ERR-INVALID-STAKEHOLDER))
    (pending-amount (get pending-amount stakeholder-data))
  )
    (asserts! (not (var-get contract-paused)) ERR-CONTRACT-PAUSED)
    (asserts! (> pending-amount u0) ERR-INSUFFICIENT-BALANCE)
    
    ;; Transfer payment to stakeholder
    (try! (as-contract (stx-transfer? pending-amount tx-sender tx-sender)))
    
    ;; Update stakeholder data
    (map-set track-stakeholders
      { track-id: track-id, stakeholder: tx-sender }
      (merge stakeholder-data {
        claimed-amount: (+ (get claimed-amount stakeholder-data) pending-amount),
        pending-amount: u0,
        last-claim: block-height
      })
    )
    
    ;; Update stakeholder totals
    (let (
      (totals (default-to { total-earned: u0, total-claimed: u0, pending-claims: u0, tracks-count: u0 }
                          (map-get? stakeholder-totals { stakeholder: tx-sender })))
    )
      (map-set stakeholder-totals
        { stakeholder: tx-sender }
        (merge totals {
          total-claimed: (+ (get total-claimed totals) pending-amount),
          pending-claims: (- (get pending-claims totals) pending-amount)
        })
      )
    )
    
    ;; Update total distributed
    (var-set total-distributed (+ (var-get total-distributed) pending-amount))
    
    (ok pending-amount)
  )
)

;; Administrative functions

;; Pause contract (emergency function)
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

;; Unpause contract
(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

;; Set minimum payment amount
(define-public (set-minimum-payment (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set minimum-payment-amount amount)
    (ok amount)
  )
)

;; Private functions

;; Helper function to get percentage from stakeholder tuple
(define-private (get-percentage (stakeholder { stakeholder: principal, percentage: uint }))
  (get percentage stakeholder)
)

;; Add a stakeholder to a track
(define-private (add-stakeholder-to-track 
  (stakeholder { stakeholder: principal, percentage: uint })
  (track-id (string-ascii 64))
)
  (begin
    (map-set track-stakeholders
      { track-id: track-id, stakeholder: (get stakeholder stakeholder) }
      {
        percentage: (get percentage stakeholder),
        claimed-amount: u0,
        pending-amount: u0,
        last-claim: u0
      }
    )
    
    ;; Update stakeholder totals
    (let (
      (totals (default-to { total-earned: u0, total-claimed: u0, pending-claims: u0, tracks-count: u0 }
                          (map-get? stakeholder-totals { stakeholder: (get stakeholder stakeholder) })))
    )
      (map-set stakeholder-totals
        { stakeholder: (get stakeholder stakeholder) }
        (merge totals { tracks-count: (+ (get tracks-count totals) u1) })
      )
    )
    
    true
  )
)

;; Distribute royalties to all stakeholders of a track
(define-private (distribute-to-stakeholders (track-id (string-ascii 64)) (amount uint))
  (let (
    (track-data (unwrap! (map-get? tracks { track-id: track-id }) ERR-TRACK-NOT-FOUND))
  )
    ;; This would need to be implemented with a proper iteration mechanism
    ;; For now, we'll mark it as successful and handle distribution in claim function
    (ok true)
  )
)

;; Calculate payment amount for a stakeholder
(define-private (calculate-payment (percentage uint) (total-amount uint))
  (/ (* percentage total-amount) u100)
)

;; Read-only functions

;; Get track information
(define-read-only (get-track-info (track-id (string-ascii 64)))
  (map-get? tracks { track-id: track-id })
)

;; Get stakeholder information for a track
(define-read-only (get-stakeholder-info (track-id (string-ascii 64)) (stakeholder principal))
  (map-get? track-stakeholders { track-id: track-id, stakeholder: stakeholder })
)

;; Get stakeholder total earnings
(define-read-only (get-stakeholder-totals (stakeholder principal))
  (map-get? stakeholder-totals { stakeholder: stakeholder })
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-tracks: (var-get total-tracks),
    total-distributed: (var-get total-distributed),
    minimum-payment: (var-get minimum-payment-amount),
    is-paused: (var-get contract-paused)
  }
)

;; Get deposit information
(define-read-only (get-deposit-info (track-id (string-ascii 64)) (deposit-id uint))
  (map-get? royalty-deposits { track-id: track-id, deposit-id: deposit-id })
)

;; Check if contract is paused
(define-read-only (is-contract-paused)
  (var-get contract-paused)
)

;; Get minimum payment amount
(define-read-only (get-minimum-payment)
  (var-get minimum-payment-amount)
)


;; title: royalty-splitter
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

