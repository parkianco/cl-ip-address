;;;; cl-ip-address.asd
;;;; IPv4/IPv6 parsing with zero external dependencies

(asdf:defsystem #:cl-ip-address
  :description "Pure Common Lisp IPv4/IPv6 address parsing library"
  :author "Parkian Company LLC"
  :license "BSD-3-Clause"
  :version "1.0.0"
  :serial t
  :components ((:file "package")
               (:module "src"
                :serial t
                :components ((:file "ip-address")))))
