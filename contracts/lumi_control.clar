;; LumiChain - Decentralized Lighting Control Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_DEVICE_NOT_FOUND (err u101)) 
(define-constant ERR_INVALID_PARAMS (err u102))
(define-constant ERR_GROUP_NOT_FOUND (err u103))
(define-constant ERR_SCHEDULE_NOT_FOUND (err u104))
(define-constant ERR_ALREADY_EXISTS (err u105))
(define-constant ERR_INVALID_BLOCK (err u106))
(define-constant ERR_INVALID_ACTION (err u107))

;; [Previous map definitions remain unchanged...]

;; Helper Functions
(define-private (is-valid-action (action (string-ascii 20)))
    (or
        (is-eq action "toggle")
        (is-eq action "brightness")
        (is-eq action "on")
        (is-eq action "off")
    )
)

(define-private (verify-target-ownership (target-id uint) (target-type (string-ascii 10)))
    (if (is-eq target-type "device")
        (match (map-get? devices {device-id: target-id})
            device (is-eq tx-sender (get owner device))
            false
        )
        (match (map-get? device-groups {group-id: target-id})
            group (is-eq tx-sender (get owner group))
            false
        )
    )
)

;; [Previous functions remain unchanged until create-schedule]

;; Create Schedule
(define-public (create-schedule (schedule-id uint) (target-id uint) (target-type (string-ascii 10)) (action (string-ascii 20)) (value uint) (trigger-block uint))
    (begin
        (asserts! (is-none (map-get? schedules {schedule-id: schedule-id})) ERR_ALREADY_EXISTS)
        (asserts! (> trigger-block block-height) ERR_INVALID_BLOCK)
        (asserts! (or (is-eq target-type "device") (is-eq target-type "group")) ERR_INVALID_PARAMS)
        (asserts! (is-valid-action action) ERR_INVALID_ACTION)
        (asserts! (verify-target-ownership target-id target-type) ERR_NOT_AUTHORIZED)
        (ok (map-set schedules
            { schedule-id: schedule-id }
            {
                owner: tx-sender,
                target-id: target-id,
                target-type: target-type,
                action: action,
                value: value,
                trigger-block: trigger-block,
                is-active: true
            }
        ))
    )
)

;; Deactivate Schedule
(define-public (deactivate-schedule (schedule-id uint))
    (let (
        (schedule (unwrap! (map-get? schedules {schedule-id: schedule-id}) ERR_SCHEDULE_NOT_FOUND))
    )
        (asserts! (is-eq tx-sender (get owner schedule)) ERR_NOT_AUTHORIZED)
        (ok (map-set schedules
            { schedule-id: schedule-id }
            (merge schedule { is-active: false })
        ))
    )
)

;; [Previous read-only functions remain unchanged]
