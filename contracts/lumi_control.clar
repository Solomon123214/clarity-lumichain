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

;; [Previous map definitions remain unchanged...]

;; Device Registration
(define-public (register-device (device-id uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (is-none (map-get? devices {device-id: device-id})) ERR_ALREADY_EXISTS)
        (ok (map-set devices
            { device-id: device-id }
            {
                owner: tx-sender,
                is-on: false,
                brightness: u0,
                last-updated: block-height,
                group-id: none
            }
        ))
    )
)

;; [Previous functions remain unchanged until add-to-group]

;; Add Device to Group
(define-public (add-to-group (device-id uint) (group-id uint))
    (let (
        (device (unwrap! (map-get? devices {device-id: device-id}) ERR_DEVICE_NOT_FOUND))
        (group (unwrap! (map-get? device-groups {group-id: group-id}) ERR_GROUP_NOT_FOUND))
    )
        (asserts! (is-eq tx-sender (get owner device)) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq tx-sender (get owner group)) ERR_NOT_AUTHORIZED)
        (ok (map-set devices
            { device-id: device-id }
            (merge device { group-id: (some group-id) })
        ))
    )
)

;; Remove Device from Group
(define-public (remove-from-group (device-id uint))
    (let (
        (device (unwrap! (map-get? devices {device-id: device-id}) ERR_DEVICE_NOT_FOUND))
    )
        (asserts! (is-eq tx-sender (get owner device)) ERR_NOT_AUTHORIZED)
        (ok (map-set devices
            { device-id: device-id }
            (merge device { group-id: none })
        ))
    )
)

;; Create Schedule
(define-public (create-schedule (schedule-id uint) (target-id uint) (target-type (string-ascii 10)) (action (string-ascii 20)) (value uint) (trigger-block uint))
    (begin
        (asserts! (is-none (map-get? schedules {schedule-id: schedule-id})) ERR_ALREADY_EXISTS)
        (asserts! (> trigger-block block-height) ERR_INVALID_BLOCK)
        (asserts! (or (is-eq target-type "device") (is-eq target-type "group")) ERR_INVALID_PARAMS)
        (ok (map-set schedules
            { schedule-id: schedule-id }
            {
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
        (ok (map-set schedules
            { schedule-id: schedule-id }
            (merge schedule { is-active: false })
        ))
    )
)

;; [Previous read-only functions remain unchanged]
