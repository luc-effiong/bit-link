;; Title: BitLink - Decentralized Bitcoin Payment Request Protocol
;; Summary: A trustless, time-bound payment link system enabling seamless sBTC transactions on Stacks
;; Description: BitLink revolutionizes Bitcoin payments by creating secure, expiring payment requests
;;              that can be fulfilled by anyone. Perfect for invoicing, crowdfunding, and peer-to-peer
;;              transactions while maintaining full Bitcoin sovereignty through Stacks Layer 2.
;;              Features include automatic expiration, batch operations, comprehensive indexing,
;;              and real-time payment tracking with complete audit trails.

;; ERROR CONSTANTS

(define-constant ERR-TAG-EXISTS u100)
(define-constant ERR-NOT-PENDING u101)
(define-constant ERR-INSUFFICIENT-FUNDS u102)
(define-constant ERR-NOT-FOUND u103)
(define-constant ERR-UNAUTHORIZED u104)
(define-constant ERR-EXPIRED u105)
(define-constant ERR-INVALID-AMOUNT u106)
(define-constant ERR-EMPTY-MEMO u107)
(define-constant ERR-MAX-EXPIRATION-EXCEEDED u108)
(define-constant ERR-SELF-PAYMENT u109)
(define-constant ERR-INVALID-RECIPIENT u110)

;; STATE CONSTANTS

(define-constant STATE-PENDING "pending")
(define-constant STATE-PAID "paid")
(define-constant STATE-EXPIRED "expired")
(define-constant STATE-CANCELED "canceled")

;; PROTOCOL CONFIGURATION

;; Official sBTC token contract address
(define-constant SBTC-CONTRACT 'ST1F7QA2MDF17S807EPA36TSS8AMEFY4KA9TVGWXT.sbtc-token)

;; Contract owner for potential governance functions
(define-constant CONTRACT-OWNER tx-sender)

;; Maximum expiration time: 30 days in blocks (~10 min per block)
(define-constant MAX-EXPIRATION-BLOCKS u4320)

;; Minimum payment amount (1 satoshi equivalent)
(define-constant MIN-PAYMENT-AMOUNT u1)

;; Maximum list size for indexing
(define-constant MAX-LIST-SIZE u50)

;; Maximum batch operation size
(define-constant MAX-BATCH-SIZE u20)

;; DATA STORAGE MAPS

;; Main storage for payment requests with comprehensive metadata
(define-map payment-links
  { id: uint }
  {
    creator: principal,
    recipient: principal,
    amount: uint,
    created-at: uint,
    expires-at: uint,
    memo: (optional (string-ascii 256)),
    state: (string-ascii 16),
    payment-tx: (optional (buff 32)),
    fulfiller: (optional principal)
  }
)

;; Index mapping creators to their payment link IDs
(define-map links-by-creator
  { creator: principal }
  { ids: (list 50 uint) }
)

;; Index mapping recipients to payment link IDs assigned to them
(define-map links-by-recipient
  { recipient: principal }
  { ids: (list 50 uint) }
)

;; Index for tracking fulfilled payments by fulfiller
(define-map links-by-fulfiller
  { fulfiller: principal }
  { ids: (list 50 uint) }
)

;; STATE VARIABLES

;; Auto-incrementing counter for unique payment link IDs
(define-data-var last-id uint u0)

;; Protocol statistics
(define-data-var total-links-created uint u0)
(define-data-var total-links-fulfilled uint u0)
(define-data-var total-volume uint u0)

;; PRIVATE HELPER FUNCTIONS

;; Add payment link ID to a principal's creator index list
(define-private (add-id-to-creator-list (user principal) (id uint))
  (let (
    (current-data (default-to { ids: (list) } (map-get? links-by-creator { creator: user })))
    (current-list (get ids current-data))
    (new-list (unwrap! (as-max-len? (append current-list id) u50) current-list))
  )
  (begin
    (map-set links-by-creator { creator: user } { ids: new-list })
    new-list
  ))
)