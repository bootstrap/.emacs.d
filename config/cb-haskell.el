;;; cb-haskell.el --- Configuration for Haskell.  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Chris Barrett

;; Author: Chris Barrett <chris+emacs@walrus.cool>

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'use-package))

(require 'spacemacs-keys)

(autoload 'evil-define-key "evil-core")

(use-package haskell-mode
  :mode
  (("\\.[gh]s\\'" . haskell-mode)
   ("\\.l[gh]s\\'" . literate-haskell-mode)
   ("\\.hsc\\'" . haskell-mode))

  :interpreter
  (("runghc" . haskell-mode)
   ("runhaskell" . haskell-mode))

  :init
  (progn
    (add-to-list 'completion-ignored-extensions ".hi")
    (add-to-list 'completion-ignored-extensions ".gm"))

  :preface
  (defun cb-haskell--set-indentation-step ()
    (with-no-warnings (setq evil-shift-width 4))
    (setq tab-width 4))

  :config
  (progn
    ;; Use 4 space indentation style.

    (setq haskell-indentation-layout-offset 4)
    (setq haskell-indentation-starter-offset 2)
    (setq haskell-indentation-where-pre-offset 2)
    (setq haskell-indentation-where-post-offset 2)
    (setq haskell-indentation-left-offset 4)
    (setq haskell-indent-spaces 4)

    (add-hook 'haskell-mode-hook #'cb-haskell--set-indentation-step)))


(use-package haskell-customize
  :after haskell-mode
  :config
  (progn
    (setq haskell-stylish-on-save t)
    (setq haskell-completing-read-function #'completing-read)
    (setq haskell-interactive-popup-errors nil)))


(use-package haskell-compile
  :after haskell-mode
  :commands (haskell-compile)
  :config
  (progn
    (spacemacs-keys-set-leader-keys-for-major-mode 'haskell-mode
      "c" #'haskell-compile)

    (setq haskell-compile-cabal-build-command "stack build --ghc-options -ferror-spans")))


(use-package haskell-cabal
  :after haskell-mode
  :config
  (define-key haskell-cabal-mode-map (kbd "C-c C-c") 'haskell-compile))


(use-package haskell-doc
  :after haskell-mode)


(use-package haskell-interactive-mode
  :after haskell-mode
  :commands (interactive-haskell-mode)
  :init
  (add-hook 'haskell-mode-hook #'interactive-haskell-mode))


(use-package haskell-debug
  :after haskell-mode
  :config
  (with-no-warnings
    (evilified-state-evilify-map haskell-debug-mode-map
      :mode haskell-debug-mode
      :bindings
      (kbd "n") #'haskell-debug/next
      (kbd "N") #'haskell-debug/previous
      (kbd "p") #'haskell-debug/previous
      (kbd "q") #'quit-window)))


(use-package haskell-presentation-mode
  :after haskell-mode
  :config
  (evil-define-key 'normal haskell-presentation-mode-map (kbd "q") #'quit-window))


(use-package haskell-autoinsert
  :functions (haskell-autoinsert-init)
  :config (haskell-autoinsert-init))


(use-package haskell-imports
  :after haskell-mode
  :commands (haskell-imports-insert-unqualified
             haskell-imports-insert-qualified)
  :config
  (spacemacs-keys-set-leader-keys-for-major-mode 'haskell-mode
    "ii" #'haskell-imports-insert-unqualified
    "iq" #'haskell-imports-insert-qualified))


(use-package intero
  :after haskell-mode

  :commands (intero-mode intero-targets intero-goto-definition)

  :preface
  (progn
    (autoload 'intero-mode-map "intero")

    (defun cb-haskell--maybe-intero-mode ()
      (unless (or (derived-mode-p 'ghc-core-mode)
                  (equal (get major-mode 'mode-class) 'special))
        (intero-mode +1))))

  :init
  (add-hook 'haskell-mode-hook #'cb-haskell--maybe-intero-mode)

  :bind
  (:map
   intero-mode-map
   ("M-." . intero-goto-definition)
   ("M-," . pop-tag-mark))

  :config
  (progn
    (spacemacs-keys-set-leader-keys-for-major-mode 'haskell-mode
      "t" #'intero-targets)

    (with-no-warnings
      (evil-define-key 'normal intero-mode-map (kbd "M-.") #'intero-goto-definition)
      (evil-define-key 'normal intero-mode-map (kbd "M-,") #'pop-tag-mark))))


(use-package stack-hoogle
  :after haskell-mode
  :commands (stack-hoogle stack-hoogle-info-at-pt)
  :bind
  (:map haskell-mode-map ("C-c C-h" . stack-hoogle))
  :config
  (evil-define-key 'normal haskell-mode-map (kbd "K") #'stack-hoogle-info-at-pt))


(provide 'cb-haskell)

;;; cb-haskell.el ends here