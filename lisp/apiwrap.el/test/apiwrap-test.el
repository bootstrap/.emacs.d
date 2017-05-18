;;; Example/test file
(require 'apiwrap)
(require 'cl-lib)
(require 'dash)

(defun test-alists-equal-p (a b)
  "Test if A and B are equal.
If they're both alists, disregard key ordering."
  (if (and (listp a)
           (listp b)
           (null (cdr (last a)))      ;is it a list?
           (null (cdr (last b)))
           (-all-p #'consp a)         ;is it an alist?
           (-all-p #'consp b))
      (and (--all-p (and (test-alists-equal-p (car (assoc it a)) (car (assoc it b)))
                         (test-alists-equal-p (cdr (assoc it a)) (cdr (assoc it b))))
                    (mapcar #'car a))
           (--all-p (and (test-alists-equal-p (car (assoc it a)) (car (assoc it b)))
                         (test-alists-equal-p (cdr (assoc it a)) (cdr (assoc it b))))
                    (mapcar #'car b)))
    (equal a b)))

(defvar test-responses nil)
(defun test-request (url &optional params data)
  "Respond to each identical request identically."
  (cdr
   (let ((request `((url . ,url) (params . ,params) (data . ,data))))
     (or (-find (lambda (c) (test-alists-equal-p request (car c)))
                test-responses)
         (car (push (cons request (cl-gensym)) test-responses))))))

(eval-and-compile
  (defalias 'test-get #'test-request)
  (defalias 'test-put #'test-request)
  (defalias 'test-head #'test-request)
  (defalias 'test-post #'test-request)
  (defalias 'test-patch #'test-request)
  (defalias 'test-delete #'test-request)

  (defun apiwrap-test--gen-link (link-alist)
    (format "link: %s" (alist-get 'link link-alist)))

  (apiwrap-new-backend "Test" "test"
                       '((sym1 . "SYM1 is a special object.")
                         (symbol-two . "SYMBOL-TWO is a special object."))
                       :get #'test-get :put #'test-put :head #'test-head
                       :post #'test-post :patch #'test-patch :delete #'test-delete
                       :link #'apiwrap-test--gen-link))

(ert-deftest apiwrap-macros ()
  (should (equal 'test-get-some-method
                 (defapiget-test "/some/method" "Documentation" "link")))
  (should (equal 'test-get-echo-one-arg
                 (defapiget-test "/echo/:one/:arg"
                   "Documentation" "link"
                   (symbol-two) "/echo/:symbol-two.a/:symbol-two.b")))
  (should (equal 'test-get-echo-two-args
                 (defapiget-test "/echo/:two/:args"
                   "Documentation" "link"
                   (sym1 symbol-two) "/echo/:sym1.a/:symbol-two.b"))))

(ert-deftest apiwrap-usage ()
  (should (equal (test-get-some-method)
                 (test-request "/some/method")))
  (should (equal (test-get-echo-one-arg '((a . "value-for-a") (b . "value for b")))
                 (test-get "/echo/value-for-a/value%20for%20b")))
  (should (equal (test-get-some-method :arg-1 "1" :arg-2 "2")
                 (test-get "/some/method" '((arg-1 . "1") (arg-2 . "2"))))))

(ert-deftest apiwrap-resolve-params ()
  (let ((obj '((name . "Hello-World")
               (owner (login . "octocat"))))
        (tests '(("/repos/:owner.login/:name/issues" . "/repos/octocat/Hello-World/issues")
                 ("/repos/:owner.login/:name" . "/repos/octocat/Hello-World")
                 ("/:owner.login/:name/issues" . "/octocat/Hello-World/issues")
                 ("/:owner.login/:name" . "/octocat/Hello-World")
                 (":owner.login" . "octocat")
                 ("/:owner.login" . "/octocat")
                 ("/:owner.login/" . "/octocat/"))))
    (dolist (test tests)
      (should (string= (cdr test) (eval (apiwrap-resolve-api-params 'obj (car test)))))))
  (should (string= (let ((obj '((name . "hello^world")
                                (owner (login . "octo^cat")))))
                     (eval (apiwrap-resolve-api-params 'obj "/:owner.login/:name")))
                   "/octo%5Ecat/hello%5Eworld")))

(ert-deftest apiwrap-plist-to-alist ()
  (should
   (null (cl-set-difference
          (apiwrap-plist->alist '(:one two :three four))
          '((one . two) (three . four))
          :test #'equal))))
