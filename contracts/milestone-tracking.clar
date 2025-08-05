;; Contract Milestone Tracking Contract
;; Monitors project progress and automates payments upon completion

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-CONTRACT-NOT-FOUND (err u301))
(define-constant ERR-MILESTONE-NOT-FOUND (err u302))
(define-constant ERR-INVALID-STATUS (err u303))
(define-constant ERR-MILESTONE-ALREADY-COMPLETED (err u304))
(define-constant ERR-INSUFFICIENT-FUNDS (err u305))
(define-constant ERR-INVALID-MILESTONE (err u306))

;; Data Variables
(define-data-var next-contract-id uint u1)
(define-data-var next-milestone-id uint u1)

;; Data Maps
(define-map contracts
  { contract-id: uint }
  {
    procurement-id: uint,
    vendor-id: uint,
    contractor: principal,
    contract-value: uint,
    start-date: uint,
    end-date: uint,
    status: (string-ascii 20),
    total-milestones: uint,
    completed-milestones: uint,
    total-paid: uint,
    created-by: principal,
    created-at: uint
  }
)

(define-map milestones
  { milestone-id: uint }
  {
    contract-id: uint,
    milestone-number: uint,
    title: (string-ascii 200),
    description: (string-ascii 500),
    payment-amount: uint,
    due-date: uint,
    status: (string-ascii 20),
    completion-evidence: (optional (string-ascii 64)),
    completed-at: (optional uint),
    approved-by: (optional principal),
    approved-at: (optional uint)
  }
)

(define-map contract-milestones
  { contract-id: uint, milestone-number: uint }
  { milestone-id: uint }
)

(define-map milestone-payments
  { milestone-id: uint }
  {
    amount: uint,
    paid-to: principal,
    paid-at: uint,
    transaction-hash: (string-ascii 64)
  }
)

;; Read-only functions
(define-read-only (get-contract (contract-id uint))
  (map-get? contracts { contract-id: contract-id })
)

(define-read-only (get-milestone (milestone-id uint))
  (map-get? milestones { milestone-id: milestone-id })
)

(define-read-only (get-contract-milestone (contract-id uint) (milestone-number uint))
  (match (map-get? contract-milestones { contract-id: contract-id, milestone-number: milestone-number })
    milestone-data (get-milestone (get milestone-id milestone-data))
    none
  )
)

(define-read-only (get-milestone-payment (milestone-id uint))
  (map-get? milestone-payments { milestone-id: milestone-id })
)

(define-read-only (calculate-completion-percentage (contract-id uint))
  (match (get-contract contract-id)
    contract-data
    (let
      (
        (total (get total-milestones contract-data))
        (completed (get completed-milestones contract-data))
      )
      (if (> total u0)
        (/ (* completed u100) total)
        u0
      )
    )
    u0
  )
)

(define-read-only (is-contract-overdue (contract-id uint))
  (match (get-contract contract-id)
    contract-data
    (and
      (not (is-eq (get status contract-data) "completed"))
      (> block-height (get end-date contract-data))
    )
    false
  )
)

;; Public functions
(define-public (create-contract
  (procurement-id uint)
  (vendor-id uint)
  (contractor principal)
  (contract-value uint)
  (duration uint)
)
  (let
    (
      (contract-id (var-get next-contract-id))
      (current-height block-height)
      (end-date (+ current-height duration))
    )
    (asserts! (> contract-value u0) ERR-INVALID-MILESTONE)
    (asserts! (> duration u0) ERR-INVALID-MILESTONE)

    (map-set contracts
      { contract-id: contract-id }
      {
        procurement-id: procurement-id,
        vendor-id: vendor-id,
        contractor: contractor,
        contract-value: contract-value,
        start-date: current-height,
        end-date: end-date,
        status: "active",
        total-milestones: u0,
        completed-milestones: u0,
        total-paid: u0,
        created-by: tx-sender,
        created-at: current-height
      }
    )

    (var-set next-contract-id (+ contract-id u1))
    (ok contract-id)
  )
)

(define-public (add-milestone
  (contract-id uint)
  (milestone-number uint)
  (title (string-ascii 200))
  (description (string-ascii 500))
  (payment-amount uint)
  (days-from-start uint)
)
  (match (get-contract contract-id)
    contract-data
    (let
      (
        (milestone-id (var-get next-milestone-id))
        (due-date (+ (get start-date contract-data) days-from-start))
      )
      (asserts! (is-eq tx-sender (get created-by contract-data)) ERR-NOT-AUTHORIZED)
      (asserts! (> payment-amount u0) ERR-INVALID-MILESTONE)
      (asserts! (<= due-date (get end-date contract-data)) ERR-INVALID-MILESTONE)
      (asserts! (is-none (map-get? contract-milestones { contract-id: contract-id, milestone-number: milestone-number })) ERR-INVALID-MILESTONE)

      (map-set milestones
        { milestone-id: milestone-id }
        {
          contract-id: contract-id,
          milestone-number: milestone-number,
          title: title,
          description: description,
          payment-amount: payment-amount,
          due-date: due-date,
          status: "pending",
          completion-evidence: none,
          completed-at: none,
          approved-by: none,
          approved-at: none
        }
      )

      (map-set contract-milestones
        { contract-id: contract-id, milestone-number: milestone-number }
        { milestone-id: milestone-id }
      )

      (map-set contracts
        { contract-id: contract-id }
        (merge contract-data {
          total-milestones: (+ (get total-milestones contract-data) u1)
        })
      )

      (var-set next-milestone-id (+ milestone-id u1))
      (ok milestone-id)
    )
    ERR-CONTRACT-NOT-FOUND
  )
)

(define-public (complete-milestone
  (contract-id uint)
  (milestone-number uint)
  (completion-evidence (string-ascii 64))
)
  (match (get-contract-milestone contract-id milestone-number)
    milestone-data
    (match (get-contract contract-id)
      contract-data
      (let
        (
          (milestone-id (unwrap! (get milestone-id (map-get? contract-milestones { contract-id: contract-id, milestone-number: milestone-number })) ERR-MILESTONE-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get contractor contract-data)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status milestone-data) "pending") ERR-MILESTONE-ALREADY-COMPLETED)

        (map-set milestones
          { milestone-id: milestone-id }
          (merge milestone-data {
            status: "submitted",
            completion-evidence: (some completion-evidence),
            completed-at: (some block-height)
          })
        )
        (ok true)
      )
      ERR-CONTRACT-NOT-FOUND
    )
    ERR-MILESTONE-NOT-FOUND
  )
)

(define-public (approve-milestone
  (contract-id uint)
  (milestone-number uint)
)
  (match (get-contract-milestone contract-id milestone-number)
    milestone-data
    (match (get-contract contract-id)
      contract-data
      (let
        (
          (milestone-id (unwrap! (get milestone-id (map-get? contract-milestones { contract-id: contract-id, milestone-number: milestone-number })) ERR-MILESTONE-NOT-FOUND))
          (payment-amount (get payment-amount milestone-data))
          (new-completed (+ (get completed-milestones contract-data) u1))
          (new-total-paid (+ (get total-paid contract-data) payment-amount))
        )
        (asserts! (is-eq tx-sender (get created-by contract-data)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status milestone-data) "submitted") ERR-INVALID-STATUS)

        (map-set milestones
          { milestone-id: milestone-id }
          (merge milestone-data {
            status: "approved",
            approved-by: (some tx-sender),
            approved-at: (some block-height)
          })
        )

        (map-set milestone-payments
          { milestone-id: milestone-id }
          {
            amount: payment-amount,
            paid-to: (get contractor contract-data),
            paid-at: block-height,
            transaction-hash: "auto-generated"
          }
        )

        (map-set contracts
          { contract-id: contract-id }
          (merge contract-data {
            completed-milestones: new-completed,
            total-paid: new-total-paid,
            status: (if (is-eq new-completed (get total-milestones contract-data)) "completed" "active")
          })
        )
        (ok payment-amount)
      )
      ERR-CONTRACT-NOT-FOUND
    )
    ERR-MILESTONE-NOT-FOUND
  )
)

(define-public (reject-milestone
  (contract-id uint)
  (milestone-number uint)
  (rejection-reason (string-ascii 500))
)
  (match (get-contract-milestone contract-id milestone-number)
    milestone-data
    (match (get-contract contract-id)
      contract-data
      (let
        (
          (milestone-id (unwrap! (get milestone-id (map-get? contract-milestones { contract-id: contract-id, milestone-number: milestone-number })) ERR-MILESTONE-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get created-by contract-data)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status milestone-data) "submitted") ERR-INVALID-STATUS)

        (map-set milestones
          { milestone-id: milestone-id }
          (merge milestone-data {
            status: "rejected",
            completion-evidence: none,
            completed-at: none
          })
        )
        (ok true)
      )
      ERR-CONTRACT-NOT-FOUND
    )
    ERR-MILESTONE-NOT-FOUND
  )
)

(define-public (extend-contract
  (contract-id uint)
  (additional-days uint)
)
  (match (get-contract contract-id)
    contract-data
    (begin
      (asserts! (is-eq tx-sender (get created-by contract-data)) ERR-NOT-AUTHORIZED)
      (asserts! (> additional-days u0) ERR-INVALID-MILESTONE)

      (map-set contracts
        { contract-id: contract-id }
        (merge contract-data {
          end-date: (+ (get end-date contract-data) additional-days)
        })
      )
      (ok true)
    )
    ERR-CONTRACT-NOT-FOUND
  )
)
