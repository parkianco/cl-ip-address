;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; cl-ip-address.asd
;;;; IPv4/IPv6 parsing with zero external dependencies

(asdf:defsystem #:cl-ip-address
  :description "Pure Common Lisp IPv4/IPv6 address parsing library"
  :author "Parkian Company LLC"
  :license "BSD-3-Clause"
  :version "0.1.0"
  :serial t
  :components ((:file "package")
               (:module "src"
                :serial t
                :components ((:file "ip-address")))))

(asdf:defsystem #:cl-ip-address/test
  :description "Tests for cl-ip-address"
  :depends-on (#:cl-ip-address)
  :serial t
  :components ((:module "test"
                :components ((:file "test-ip-address"))))
  :perform (asdf:test-op (o c)
             (let ((result (uiop:symbol-call :cl-ip-address.test :run-tests)))
               (unless result
                 (error "Tests failed")))))
