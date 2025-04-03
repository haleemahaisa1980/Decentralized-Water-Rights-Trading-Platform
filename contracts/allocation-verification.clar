;; Allocation Verification Contract
;; Validates available water quantities

(define-map water-allocations
  { year: uint, region: (string-utf8 50) }
  { total-volume: uint, allocated-volume: uint }
)

;; Set the total water allocation for a region and year
(define-public (set-total-allocation (year uint) (region (string-utf8 50)) (total-volume uint))
  (begin
    ;; Only contract owner or authorized entity can set allocations
    (asserts! (is-eq tx-sender contract-owner) (err u1))

    (map-set water-allocations
      { year: year, region: region }
      { total-volume: total-volume, allocated-volume: u0 }
    )

    (ok true)
  )
)

;; Get the allocation for a region and year
(define-read-only (get-allocation (year uint) (region (string-utf8 50)))
  (map-get? water-allocations { year: year, region: region })
)

;; Verify if a requested allocation is available
(define-read-only (verify-allocation-available (year uint) (region (string-utf8 50)) (requested-volume uint))
  (let
    (
      (allocation (default-to { total-volume: u0, allocated-volume: u0 }
                   (map-get? water-allocations { year: year, region: region })))
      (available-volume (- (get total-volume allocation) (get allocated-volume allocation)))
    )
    (if (<= requested-volume available-volume)
      (ok true)
      (err u2) ;; Not enough water available
    )
  )
)

;; Record a new allocation (called by the registration contract)
(define-public (record-allocation (year uint) (region (string-utf8 50)) (volume uint))
  (let
    (
      (allocation (default-to { total-volume: u0, allocated-volume: u0 }
                   (map-get? water-allocations { year: year, region: region })))
      (new-allocated-volume (+ (get allocated-volume allocation) volume))
    )
    ;; Verify there's enough water available
    (asserts! (<= new-allocated-volume (get total-volume allocation)) (err u2))

    ;; Update the allocated volume
    (map-set water-allocations
      { year: year, region: region }
      {
        total-volume: (get total-volume allocation),
        allocated-volume: new-allocated-volume
      }
    )

    (ok true)
  )
)

;; Release allocation (when rights expire or are deactivated)
(define-public (release-allocation (year uint) (region (string-utf8 50)) (volume uint))
  (let
    (
      (allocation (default-to { total-volume: u0, allocated-volume: u0 }
                   (map-get? water-allocations { year: year, region: region })))
      (new-allocated-volume (- (get allocated-volume allocation) volume))
    )
    ;; Ensure we don't underflow
    (asserts! (>= (get allocated-volume allocation) volume) (err u3))

    ;; Update the allocated volume
    (map-set water-allocations
      { year: year, region: region }
      {
        total-volume: (get total-volume allocation),
        allocated-volume: new-allocated-volume
      }
    )

    (ok true)
  )
)

;; Contract owner
(define-constant contract-owner tx-sender)

