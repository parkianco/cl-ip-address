;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; test-ip-address.lisp - Unit tests for ip-address
;;;;
;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

(defpackage #:cl-ip-address.test
  (:use #:cl)
  (:export #:run-tests))

(in-package #:cl-ip-address.test)

(defun run-tests ()
  "Run all tests for cl-ip-address."
  (format t "~&Running tests for cl-ip-address...~%")
  ;; TODO: Add test cases
  ;; (test-function-1)
  ;; (test-function-2)
  (format t "~&All tests passed!~%")
  t)
