;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

;;;; package.lisp
;;;; Package definition for cl-ip-address

(defpackage #:cl-ip-address
  (:use #:cl)
  (:export
   ;; IP address types
   #:ip-address
   #:ipv4-address
   #:ipv6-address
   ;; Parsing and formatting
   #:parse-ip-address
   #:ip-address-to-string
   ;; Type predicates
   #:ipv4-p
   #:ipv6-p
   #:ip-address-p
   ;; Subnet operations
   #:make-subnet
   #:subnet
   #:ip-in-subnet-p
   #:subnet-contains-p
   #:subnet-network
   #:subnet-prefix-length
   ;; Special address predicates
   #:localhost-p
   #:private-ip-p
   #:loopback-p
   #:multicast-p
   #:link-local-p
   ;; Accessors
   #:ip-address-bytes
   #:ip-address-version
   ;; Conditions
   #:ip-parse-error
   #:invalid-ip-address))
