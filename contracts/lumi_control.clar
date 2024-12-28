;; LumiChain - Decentralized Lighting Control Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_DEVICE_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PARAMS (err u102))

;; Data Variables
(define-map devices
    { device-id: uint }
    {
        owner: principal,
        is-on: bool,
        brightness: uint,
        last-updated: uint
    }
)

(define-map device-history
    { device-id: uint, timestamp: uint }
    {
        action: (string-ascii 20),
        value: uint
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
                last-updated: block-height
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