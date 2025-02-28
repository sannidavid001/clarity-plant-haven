;; PlantHaven - Gardening Social Network Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-overflow (err u105))

;; Define fungible token for rewards
(define-fungible-token plant-token)

;; Data Variables
(define-data-var challenge-counter uint u0)
(define-data-var swap-counter uint u0)
(define-data-var plant-counter uint u0)

;; Data Maps
(define-map Users principal 
  {
    username: (string-ascii 50),
    reputation: uint,
    expert-status: bool
  }
)

(define-map Plants uint 
  {
    owner: principal,
    name: (string-ascii 100),
    description: (string-ascii 500),
    care-instructions: (string-ascii 1000),
    listed-for-swap: bool
  }
)

(define-map Challenges uint 
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    reward: uint,
    start-block: uint,
    end-block: uint,
    active: bool
  }
)

(define-map PlantSwaps uint 
  {
    creator: principal,
    plant-id: uint,
    requested-plant-type: (string-ascii 100),
    status: (string-ascii 20)
  }
)

;; Public Functions

;; User Management
(define-public (register-user (username (string-ascii 50)))
  (let
    ((user-data {username: username, reputation: u0, expert-status: false}))
    (asserts! (> (len username) u0) err-invalid-input)
    (if (map-get? Users tx-sender)
      err-already-exists
      (begin
        (map-set Users tx-sender user-data)
        (print {event: "user-registered", user: tx-sender, username: username})
        (ok true)))
  )
)

;; Plant Management
(define-public (add-plant (name (string-ascii 100)) 
                         (description (string-ascii 500))
                         (care-instructions (string-ascii 1000)))
  (let
    ((plant-data {
      owner: tx-sender,
      name: name,
      description: description,
      care-instructions: care-instructions,
      listed-for-swap: false
    }))
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (< (var-get plant-counter) (- (pow u2 u64) u1)) err-overflow)
    (map-set Plants (var-get plant-counter) plant-data)
    (print {event: "plant-added", id: (var-get plant-counter), owner: tx-sender})
    (var-set plant-counter (+ (var-get plant-counter) u1))
    (ok (- (var-get plant-counter) u1))
  )
)

;; Challenge Management
(define-public (create-challenge (title (string-ascii 100))
                               (description (string-ascii 500))
                               (reward uint)
                               (duration uint))
  (if (is-eq tx-sender contract-owner)
    (let
      ((challenge-data {
        title: title,
        description: description,
        reward: reward,
        start-block: block-height,
        end-block: (+ block-height duration),
        active: true
      }))
      (asserts! (> (len title) u0) err-invalid-input)
      (asserts! (> reward u0) err-invalid-input)
      (asserts! (< (var-get challenge-counter) (- (pow u2 u64) u1)) err-overflow)
      (begin
        (map-set Challenges (var-get challenge-counter) challenge-data)
        (print {event: "challenge-created", id: (var-get challenge-counter)})
        (var-set challenge-counter (+ (var-get challenge-counter) u1))
        (ok true))
    )
    err-owner-only
  )
)

;; Plant Swap Management
(define-public (create-swap-listing (plant-id uint) 
                                  (requested-type (string-ascii 100)))
  (let
    ((plant (unwrap! (map-get? Plants plant-id) err-not-found))
     (swap-data {
       creator: tx-sender,
       plant-id: plant-id,
       requested-plant-type: requested-type,
       status: "open"
     }))
    (asserts! (> (len requested-type) u0) err-invalid-input)
    (asserts! (< (var-get swap-counter) (- (pow u2 u64) u1)) err-overflow)
    (asserts! (is-eq (get owner plant) tx-sender) err-unauthorized)
    (begin
      (map-set Plants plant-id (merge plant {listed-for-swap: true}))
      (map-set PlantSwaps (var-get swap-counter) swap-data)
      (print {event: "swap-created", id: (var-get swap-counter), plant-id: plant-id})
      (var-set swap-counter (+ (var-get swap-counter) u1))
      (ok true))
  )
)

;; Read-only functions
(define-read-only (get-user-info (user principal))
  (map-get? Users user)
)

(define-read-only (get-plant-info (plant-id uint))
  (map-get? Plants plant-id)
)

(define-read-only (get-challenge-info (challenge-id uint))
  (map-get? Challenges challenge-id)
)

(define-read-only (get-swap-info (swap-id uint))
  (map-get? PlantSwaps swap-id)
)
