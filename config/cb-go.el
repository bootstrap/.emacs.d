;;; cb-go.el --- Configuration for golang.  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Chris Barrett

;; Author: Chris Barrett <chris+emacs@walrus.cool>

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'use-package))

(require 'spacemacs-keys)

(autoload 'evil-define-key "evil-core")

(use-package go-mode
  :mode ("\\.go\\'" . go-mode)

  :init
  (progn
    (spacemacs-keys-declare-prefix-for-mode 'go-mode "me" "playground")
    (spacemacs-keys-declare-prefix-for-mode 'go-mode "mg" "goto")
    (spacemacs-keys-declare-prefix-for-mode 'go-mode "mh" "help")
    (spacemacs-keys-declare-prefix-for-mode 'go-mode "mi" "imports")

    (spacemacs-keys-set-leader-keys-for-major-mode 'go-mode
      "hh" 'godoc-at-point
      "ig" 'go-goto-imports
      "ia" 'go-import-add
      "ir" 'go-remove-unused-imports
      "eb" 'go-play-buffer
      "er" 'go-play-region
      "ed" 'go-download-play
      "ga" 'ff-find-other-file
      "gc" 'go-coverage))

  :preface
  (defun cb-go--set-local-vars ()
    (setq-local tab-width 4)
    (setq-local indent-tabs-mode t)
    (with-no-warnings
      (setq-local evil-shift-width 4)))

  :config
  (progn
    (setq gofmt-show-errors nil)
    (evil-define-key 'normal go-mode-map (kbd "K") #'godoc-at-point)

    (add-hook 'go-mode-hook #'cb-go--set-local-vars)
    (add-hook 'before-save-hook #'gofmt-before-save))

  :functions (gofmt-before-save godoc-at-point))

(use-package company-go
  :after go-mode

  :preface
  (progn
    (autoload 'company-mode "company")

    (defun cb-go-company-setup ()
      (with-no-warnings
        (setq-local company-backends '(company-go)))
      (company-mode)))

  :config
  (progn
    (with-no-warnings
      (setq company-go-show-annotation t))
    (add-hook 'go-mode-hook #'cb-go-company-setup)))

(use-package go-eldoc
  :after go-mode
  :config (add-hook 'go-mode-hook 'go-eldoc-setup))

(use-package flycheck-gometalinter
  :after go-mode
  :preface
  (progn
    (autoload 'flycheck-gometalinter-setup "flycheck-gometalinter")

    (defun cb-go--configure-metalinter ()
      "Enable `flycheck-gometalinter' and disable overlapping `flycheck' linters."
      (with-no-warnings
        (setq flycheck-disabled-checkers '(go-gofmt
                                           go-golint
                                           go-vet
                                           go-build
                                           go-test
                                           go-errcheck)))
      (flycheck-gometalinter-setup)))

  :init
  (add-hook 'go-mode-hook #'cb-go--configure-metalinter t))

(use-package cb-go-flycheck-metalinter-unique-errors
  :after flycheck-gometalinter
  :preface
  (autoload 'cb-go-flycheck-metalinter-unique-errors-init
    "cb-go-flycheck-metalinter-unique-errors")
  :config (cb-go-flycheck-metalinter-unique-errors-init))

(use-package cb-go-run
  :after go-mode
  :init
  (progn
    (spacemacs-keys-declare-prefix-for-mode 'go-mode "mt" "test")
    (spacemacs-keys-declare-prefix-for-mode 'go-mode "mx" "execute")
    (spacemacs-keys-set-leader-keys-for-major-mode
      'go-mode
      "tt" 'cb-go-run-test-current-function
      "ts" 'cb-go-run-test-current-suite
      "tp" 'cb-go-run-package-tests
      "tP" 'cb-go-run-package-tests-nested
      "xx" 'cb-go-run-main)))

(use-package autoinsert
  :preface
  (defconst cb-go-autoinsert-form
    '((go-mode . "Go")
      nil
      "package " (f-no-ext (f-filename (buffer-file-name))) \n \n
      _ \n))

  :config
  (add-to-list 'auto-insert-alist cb-go-autoinsert-form))


(provide 'cb-go)

;;; cb-go.el ends here
