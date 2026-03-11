;;;; ip-address.lisp
;;;; IPv4/IPv6 parsing implementation

(in-package #:cl-ip-address)

;;; Conditions

(define-condition ip-parse-error (error)
  ((input :initarg :input :reader ip-parse-error-input)
   (reason :initarg :reason :reader ip-parse-error-reason))
  (:report (lambda (c s)
             (format s "Invalid IP address ~S: ~A"
                     (ip-parse-error-input c)
                     (ip-parse-error-reason c)))))

(define-condition invalid-ip-address (ip-parse-error)
  ()
  (:report (lambda (c s)
             (format s "Invalid IP address: ~S" (ip-parse-error-input c)))))

;;; IP Address Types

(defstruct (ip-address (:constructor nil))
  "Base type for IP addresses."
  (bytes #() :type (simple-array (unsigned-byte 8) (*))))

(defstruct (ipv4-address (:include ip-address)
                         (:constructor %make-ipv4))
  "An IPv4 address (4 bytes).")

(defstruct (ipv6-address (:include ip-address)
                         (:constructor %make-ipv6))
  "An IPv6 address (16 bytes).")

;;; Constructors

(defun make-ipv4 (bytes)
  "Create an IPv4 address from BYTES (4 octets)."
  (assert (= (length bytes) 4))
  (%make-ipv4 :bytes (coerce bytes '(simple-array (unsigned-byte 8) (4)))))

(defun make-ipv6 (bytes)
  "Create an IPv6 address from BYTES (16 octets)."
  (assert (= (length bytes) 16))
  (%make-ipv6 :bytes (coerce bytes '(simple-array (unsigned-byte 8) (16)))))

;;; Type Predicates

(defun ip-address-p (object)
  "Return T if OBJECT is an IP address."
  (typep object 'ip-address))

(defun ipv4-p (object)
  "Return T if OBJECT is an IPv4 address."
  (typep object 'ipv4-address))

(defun ipv6-p (object)
  "Return T if OBJECT is an IPv6 address."
  (typep object 'ipv6-address))

(defun ip-address-version (address)
  "Return 4 for IPv4, 6 for IPv6."
  (etypecase address
    (ipv4-address 4)
    (ipv6-address 6)))

;;; Parsing

(defun parse-ipv4 (string)
  "Parse an IPv4 address string like \"192.168.1.1\"."
  (let ((parts (split-by-char string #\.)))
    (unless (= (length parts) 4)
      (error 'ip-parse-error :input string :reason "IPv4 requires 4 octets"))
    (let ((bytes (make-array 4 :element-type '(unsigned-byte 8))))
      (loop for part in parts
            for i from 0
            for num = (parse-integer part :junk-allowed nil)
            do (unless (and num (<= 0 num 255))
                 (error 'ip-parse-error :input string
                        :reason (format nil "Invalid octet: ~A" part)))
               (setf (aref bytes i) num))
      (make-ipv4 bytes))))

(defun parse-ipv6 (string)
  "Parse an IPv6 address string like \"2001:db8::1\"."
  (let* ((double-colon-pos (search "::" string))
         (bytes (make-array 16 :element-type '(unsigned-byte 8) :initial-element 0)))
    (if double-colon-pos
        ;; Handle :: compression
        (let* ((before (subseq string 0 double-colon-pos))
               (after (subseq string (+ double-colon-pos 2)))
               (before-groups (if (string= before "") nil (split-by-char before #\:)))
               (after-groups (if (string= after "") nil (split-by-char after #\:)))
               (total-groups (+ (length before-groups) (length after-groups)))
               (missing-groups (- 8 total-groups)))
          (when (> total-groups 8)
            (error 'ip-parse-error :input string :reason "Too many groups"))
          ;; Fill before groups
          (loop for group in before-groups
                for i from 0 by 2
                for value = (parse-hex-group group string)
                do (setf (aref bytes i) (ash value -8))
                   (setf (aref bytes (1+ i)) (logand value #xff)))
          ;; Fill after groups
          (loop for group in after-groups
                for i from (* 2 (+ (length before-groups) missing-groups)) by 2
                for value = (parse-hex-group group string)
                do (setf (aref bytes i) (ash value -8))
                   (setf (aref bytes (1+ i)) (logand value #xff))))
        ;; No compression
        (let ((groups (split-by-char string #\:)))
          (unless (= (length groups) 8)
            (error 'ip-parse-error :input string :reason "IPv6 requires 8 groups"))
          (loop for group in groups
                for i from 0 by 2
                for value = (parse-hex-group group string)
                do (setf (aref bytes i) (ash value -8))
                   (setf (aref bytes (1+ i)) (logand value #xff)))))
    (make-ipv6 bytes)))

(defun parse-hex-group (group original)
  "Parse a hex group (up to 4 hex digits)."
  (when (or (string= group "") (> (length group) 4))
    (error 'ip-parse-error :input original :reason "Invalid hex group"))
  (let ((value (parse-integer group :radix 16 :junk-allowed nil)))
    (unless (and value (<= 0 value #xffff))
      (error 'ip-parse-error :input original :reason "Invalid hex group"))
    value))

(defun parse-ip-address (string)
  "Parse an IP address string (IPv4 or IPv6)."
  (cond
    ((find #\: string) (parse-ipv6 string))
    ((find #\. string) (parse-ipv4 string))
    (t (error 'invalid-ip-address :input string :reason "Unrecognized format"))))

;;; Formatting

(defun ip-address-to-string (address)
  "Convert an IP address to its string representation."
  (etypecase address
    (ipv4-address (ipv4-to-string address))
    (ipv6-address (ipv6-to-string address))))

(defun ipv4-to-string (address)
  "Convert IPv4 address to string."
  (let ((bytes (ip-address-bytes address)))
    (format nil "~D.~D.~D.~D"
            (aref bytes 0) (aref bytes 1)
            (aref bytes 2) (aref bytes 3))))

(defun ipv6-to-string (address)
  "Convert IPv6 address to string (with :: compression)."
  (let* ((bytes (ip-address-bytes address))
         (groups (loop for i from 0 below 16 by 2
                       collect (logior (ash (aref bytes i) 8)
                                       (aref bytes (1+ i))))))
    ;; Find longest run of zeros for :: compression
    (multiple-value-bind (start length)
        (find-longest-zero-run groups)
      (if (and start (>= length 2))
          ;; Use :: compression
          (with-output-to-string (s)
            (loop for i from 0 below 8
                  do (cond
                       ((= i start)
                        (write-string (if (zerop i) "::" ":") s))
                       ((and (>= i start) (< i (+ start length)))
                        nil)  ; Skip zeros
                       (t
                        (format s "~(~X~)" (nth i groups))
                        (when (< i 7)
                          (write-char #\: s))))))
          ;; No compression
          (format nil "~(~{~X~^:~}~)" groups)))))

(defun find-longest-zero-run (groups)
  "Find the start and length of the longest run of zeros."
  (let ((best-start nil)
        (best-length 0)
        (current-start nil)
        (current-length 0))
    (loop for group in groups
          for i from 0
          do (if (zerop group)
                 (if current-start
                     (incf current-length)
                     (setf current-start i
                           current-length 1))
                 (progn
                   (when (and current-start (> current-length best-length))
                     (setf best-start current-start
                           best-length current-length))
                   (setf current-start nil
                         current-length 0))))
    (when (and current-start (> current-length best-length))
      (setf best-start current-start
            best-length current-length))
    (values best-start best-length)))

;;; Subnet

(defstruct (subnet (:constructor %make-subnet))
  "An IP subnet (network address + prefix length)."
  (network nil :type ip-address)
  (prefix-length 0 :type (integer 0 128)))

(defun make-subnet (address-or-string &optional prefix-length)
  "Create a subnet from ADDRESS/PREFIX-LENGTH or CIDR string like \"192.168.1.0/24\"."
  (if (stringp address-or-string)
      (let ((slash-pos (position #\/ address-or-string)))
        (if slash-pos
            (let* ((addr-str (subseq address-or-string 0 slash-pos))
                   (prefix-str (subseq address-or-string (1+ slash-pos)))
                   (addr (parse-ip-address addr-str))
                   (prefix (parse-integer prefix-str)))
              (%make-subnet :network addr :prefix-length prefix))
            (let ((addr (parse-ip-address address-or-string)))
              (%make-subnet :network addr
                            :prefix-length (if (ipv4-p addr) 32 128)))))
      (%make-subnet :network address-or-string
                    :prefix-length (or prefix-length
                                       (if (ipv4-p address-or-string) 32 128)))))

(defun ip-in-subnet-p (address subnet)
  "Return T if ADDRESS is within SUBNET."
  (subnet-contains-p subnet address))

(defun subnet-contains-p (subnet address)
  "Return T if SUBNET contains ADDRESS."
  (let* ((net-bytes (ip-address-bytes (subnet-network subnet)))
         (addr-bytes (ip-address-bytes address))
         (prefix (subnet-prefix-length subnet)))
    (unless (= (length net-bytes) (length addr-bytes))
      (return-from subnet-contains-p nil))
    ;; Check full bytes
    (let ((full-bytes (floor prefix 8))
          (remaining-bits (mod prefix 8)))
      (loop for i from 0 below full-bytes
            unless (= (aref net-bytes i) (aref addr-bytes i))
              do (return-from subnet-contains-p nil))
      ;; Check partial byte
      (when (and (> remaining-bits 0) (< full-bytes (length net-bytes)))
        (let ((mask (ash #xff (- 8 remaining-bits))))
          (unless (= (logand (aref net-bytes full-bytes) mask)
                     (logand (aref addr-bytes full-bytes) mask))
            (return-from subnet-contains-p nil))))
      t)))

;;; Special Address Predicates

(defun localhost-p (address)
  "Return T if ADDRESS is a localhost address."
  (loopback-p address))

(defun loopback-p (address)
  "Return T if ADDRESS is a loopback address."
  (let ((bytes (ip-address-bytes address)))
    (etypecase address
      (ipv4-address (= (aref bytes 0) 127))
      (ipv6-address (and (loop for i from 0 below 15 always (zerop (aref bytes i)))
                         (= (aref bytes 15) 1))))))

(defun private-ip-p (address)
  "Return T if ADDRESS is a private/non-routable address."
  (etypecase address
    (ipv4-address
     (let ((bytes (ip-address-bytes address)))
       (or (= (aref bytes 0) 10)                              ; 10.0.0.0/8
           (and (= (aref bytes 0) 172)                        ; 172.16.0.0/12
                (>= (aref bytes 1) 16)
                (<= (aref bytes 1) 31))
           (and (= (aref bytes 0) 192)                        ; 192.168.0.0/16
                (= (aref bytes 1) 168)))))
    (ipv6-address
     (let ((bytes (ip-address-bytes address)))
       (or (and (= (aref bytes 0) #xfc)                       ; fc00::/7 (ULA)
                (>= (aref bytes 1) 0))
           (and (= (aref bytes 0) #xfd)))))))

(defun multicast-p (address)
  "Return T if ADDRESS is a multicast address."
  (let ((bytes (ip-address-bytes address)))
    (etypecase address
      (ipv4-address (and (>= (aref bytes 0) 224)
                         (<= (aref bytes 0) 239)))
      (ipv6-address (= (aref bytes 0) #xff)))))

(defun link-local-p (address)
  "Return T if ADDRESS is a link-local address."
  (let ((bytes (ip-address-bytes address)))
    (etypecase address
      (ipv4-address (and (= (aref bytes 0) 169)
                         (= (aref bytes 1) 254)))
      (ipv6-address (and (= (aref bytes 0) #xfe)
                         (= (logand (aref bytes 1) #xc0) #x80))))))

;;; Helper Functions

(defun split-by-char (string char)
  "Split STRING by CHAR, returning a list of substrings."
  (let ((result '())
        (start 0))
    (loop for i from 0 below (length string)
          when (char= (char string i) char)
            do (push (subseq string start i) result)
               (setf start (1+ i)))
    (push (subseq string start) result)
    (nreverse result)))
