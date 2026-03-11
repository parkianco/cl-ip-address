# cl-ip-address

Pure Common Lisp IPv4/IPv6 address parsing library with zero external dependencies.

## Installation

```lisp
(asdf:load-system :cl-ip-address)
```

## Usage

```lisp
(use-package :cl-ip-address)

;; Parse IP addresses
(parse-ip-address "192.168.1.1")        ; IPv4
(parse-ip-address "2001:db8::1")        ; IPv6

;; Convert to string
(ip-address-to-string addr)

;; Type checking
(ipv4-p addr)  ; => T or NIL
(ipv6-p addr)  ; => T or NIL

;; Subnet operations
(let ((subnet (make-subnet "192.168.1.0/24")))
  (ip-in-subnet-p (parse-ip-address "192.168.1.100") subnet))
;; => T

;; Special address checks
(localhost-p (parse-ip-address "127.0.0.1"))     ; => T
(private-ip-p (parse-ip-address "192.168.1.1"))  ; => T
(multicast-p (parse-ip-address "224.0.0.1"))     ; => T
(link-local-p (parse-ip-address "169.254.1.1"))  ; => T
```

## API

- `parse-ip-address` - Parse IPv4 or IPv6 string
- `ip-address-to-string` - Convert address to string
- `ipv4-p`, `ipv6-p` - Type predicates
- `make-subnet` - Create subnet from CIDR notation
- `ip-in-subnet-p`, `subnet-contains-p` - Subnet membership
- `localhost-p`, `private-ip-p`, `loopback-p`, `multicast-p`, `link-local-p` - Address classification

## License

BSD-3-Clause. Copyright (c) 2024-2026 Parkian Company LLC.
