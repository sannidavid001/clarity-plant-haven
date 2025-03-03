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

(define-map Usernames (string-ascii 50) principal)

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

;; Private Functions
(define-private (validate-string (str (string-ascii 500))) 
  (and (> (len str) u0) (< (len str) u500))
)

;; Public Functions

;; User Management
(define-public (register-user (username (string-ascii 50)))
  (let
    ((user-data {username: username, reputation: u0, expert-status: false}))
    (asserts! (> (len username) u0) err-invalid-input)
    (asserts! (is-none (map-get? Usernames username)) err-already-exists)
    (asserts! (is-none (map-get? Users tx-sender)) err-already-exists)
    (begin
      (map-set Users tx-sender user-data)
      (map-set Usernames username tx-sender)
      (print {event: "user-registered", user: tx-sender, username: username})
      (ok true)))
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
    (asserts! (validate-string description) err-invalid-input)
    (asserts! (> (len care-instructions) u0) err-invalid-input)
    (asserts! (< (var-get plant-counter) (- (pow u2 u64) u1)) err-overflow)
    (map-set Plants (var-get plant-counter) plant-data)
    (print {event: "plant-added", id: (var-get plant-counter), owner: tx-sender})
    (var-set plant-counter (+ (var-get plant-counter) u1))
    (ok (- (var-get plant-counter) u1)))
)

;; Update Plant Information
(define-public (update-plant (plant-id uint)
                           (name (string-ascii 100))
                           (description (string-ascii 500))
                           (care-instructions (string-ascii 1000)))
  (let ((plant (unwrap! (map-get? Plants plant-id) err-not-found)))
    (asserts! (is-eq (get owner plant) tx-sender) err-unauthorized)
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (validate-string description) err-invalid-input)
    (asserts! (> (len care-instructions) u0) err-invalid-input)
    (map-set Plants plant-id
      (merge plant {
        name: name,
        description: description,
        care-instructions: care-instructions
      }))
    (ok true))
)

[Previous functions remain unchanged...]
