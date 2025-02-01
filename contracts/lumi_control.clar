;; LumiChain - Decentralized Lighting Control Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_DEVICE_NOT_FOUND (err u101)) 
(define-constant ERR_INVALID_PARAMS (err u102))
(define-constant ERR_GROUP_NOT_FOUND (err u103))
(define-constant ERR_SCHEDULE_NOT_FOUND (err u104))

;; Data Variables
(define-map devices
    { device-id: uint }
    {
        owner: principal,
        is-on: bool,
        brightness: uint,
        last-updated: uint,
        group-id: (optional uint)
    }
)

(define-map device-history
    { device-id: uint, timestamp: uint }
    {
        action: (string-ascii 20),
        value: uint
    }
)

(define-map device-groups
    { group-id: uint }
    {
        name: (string-ascii 50),
        owner: principal,
        devices: (list 20 uint)
    }
)

(define-map schedules 
    { schedule-id: uint }
    {
        target-id: uint,
        target-type: (string-ascii 10), ;; "device" or "group"
        action: (string-ascii 20),
        value: uint,
        trigger-block: uint,
        is-active: bool
    }
)

;; Device Registration
(define-public (register-device (device-id uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
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

;; Transfer Device Ownership
(define-public (transfer-device (device-id uint) (new-owner principal))
    (let (
        (device (unwrap! (map-get? devices {device-id: device-id}) ERR_DEVICE_NOT_FOUND))
    )
        (asserts! (is-eq tx-sender (get owner device)) ERR_NOT_AUTHORIZED)
        (ok (map-set devices
            { device-id: device-id }
            (merge device { owner: new-owner })
        ))
    )
)

;; Toggle Light State
(define-public (toggle-light (device-id uint))
    (let (
        (device (unwrap! (map-get? devices {device-id: device-id}) ERR_DEVICE_NOT_FOUND))
    )
        (asserts! (is-eq tx-sender (get owner device)) ERR_NOT_AUTHORIZED)
        (map-set device-history
            { device-id: device-id, timestamp: block-height }
            { action: "toggle", value: (if (get is-on device) u0 u1) }
        )
        (ok (map-set devices
            { device-id: device-id }
            (merge device {
                is-on: (not (get is-on device)),
                last-updated: block-height
            })
        ))
    )
)

;; Set Brightness
(define-public (set-brightness (device-id uint) (level uint))
    (let (
        (device (unwrap! (map-get? devices {device-id: device-id}) ERR_DEVICE_NOT_FOUND))
    )
        (asserts! (is-eq tx-sender (get owner device)) ERR_NOT_AUTHORIZED)
        (asserts! (<= level u100) ERR_INVALID_PARAMS)
        (map-set device-history
            { device-id: device-id, timestamp: block-height }
            { action: "brightness", value: level }
        )
        (ok (map-set devices
            { device-id: device-id }
            (merge device {
                brightness: level,
                last-updated: block-height
            })
        ))
    )
)

;; Create Device Group
(define-public (create-group (group-id uint) (name (string-ascii 50)))
    (ok (map-set device-groups
        { group-id: group-id }
        {
            name: name,
            owner: tx-sender,
            devices: (list)
        }
    ))
)

;; Add Device to Group
(define-public (add-to-group (device-id uint) (group-id uint))
    (let (
        (device (unwrap! (map-get? devices {device-id: device-id}) ERR_DEVICE_NOT_FOUND))
        (group (unwrap! (map-get? device-groups {group-id: group-id}) ERR_GROUP_NOT_FOUND))
    )
        (asserts! (is-eq tx-sender (get owner device)) ERR_NOT_AUTHORIZED)
        (ok (map-set devices
            { device-id: device-id }
            (merge device { group-id: (some group-id) })
        ))
    )
)

;; Create Schedule
(define-public (create-schedule (schedule-id uint) (target-id uint) (target-type (string-ascii 10)) (action (string-ascii 20)) (value uint) (trigger-block uint))
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

;; Read Only Functions
(define-read-only (get-device-info (device-id uint))
    (ok (map-get? devices {device-id: device-id}))
)

(define-read-only (get-device-status (device-id uint))
    (let (
        (device (unwrap! (map-get? devices {device-id: device-id}) ERR_DEVICE_NOT_FOUND))
    )
        (ok {
            is-on: (get is-on device),
            brightness: (get brightness device)
        })
    )
)

(define-read-only (get-group-info (group-id uint))
    (ok (map-get? device-groups {group-id: group-id}))
)

(define-read-only (get-schedule (schedule-id uint))
    (ok (map-get? schedules {schedule-id: schedule-id}))
)
