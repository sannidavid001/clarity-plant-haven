;; PlantHaven - Gardening Social Network Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))

;; Define fungible token for rewards
(define-fungible-token plant-token)

;; Data Variables
(define-data-var challenge-counter uint u0)
(define-data-var swap-counter uint u0)

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
    (if (map-get? Users tx-sender)
      err-already-exists
      (begin
        (map-set Users tx-sender user-data)
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
    (map-set Plants (var-get plant-counter) plant-data)
    (ok (var-get plant-counter))
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
      (begin
        (map-set Challenges (var-get challenge-counter) challenge-data)
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
    (if (is-eq (get owner plant) tx-sender)
      (begin
        (map-set PlantSwaps (var-get swap-counter) swap-data)
        (var-set swap-counter (+ (var-get swap-counter) u1))
        (ok true))
      err-unauthorized
    )
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