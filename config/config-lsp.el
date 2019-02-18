;;; config-lsp.el --- Configuration for Language Server Protocol client  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(eval-when-compile
  (require 'use-package))

(defvar lsp-dockerfile-server "docker-langserver")

(use-package lsp-mode
  :straight t
  :config
  (general-setq lsp-eldoc-render-all nil
                lsp-inhibit-message t
                lsp-highlight-symbol-at-point nil)
  :hook ((c-mode-common . lsp)
         (dockerfile-mode . lsp)
         (go . lsp)
         (groovy . lsp)
         (python . lsp)
         (rust-mode . lsp)
         (sh-mode . lsp)
         (web-mode . lsp))
  :config
  (progn
    (lsp-register-client
     (make-lsp-client :new-connection (lsp-stdio-connection (format "%s --stdio" lsp-dockerfile-server))
                      :major-modes '(dockerfile-mode)
                      :server-id 'dockerfile))))

(use-package lsp-java
  ;; TODO: re-enable once the library is updated to use latest lsp API.
  :disabled t
  :straight t
  :preface
  (defun config-lsp--java-mode-setup ()
    (setq-local company-backends '(company-lsp)))
  :init
  (add-hook 'java-mode-hook #'config-lsp--java-mode-setup)
  :config
  (let ((cache-dir (f-join paths-cache-directory "lsp-java")))
    (f-mkdir cache-dir)
    (general-setq lsp-java-server-install-dir (f-join cache-dir "eclipse.jdt.ls/server/")
                  lsp-java-workspace-dir (f-join cache-dir "workspace/")
                  lsp-java-workspace-cache-dir (f-join cache-dir "workspace" ".cache/"))))

(use-package company-lsp
  :after company
  :straight t
  :config
  (general-setq company-lsp-cache-candidates t
                company-lsp-async t))

(use-package lsp-ui
  :straight t
  :hook (lsp-mode . lsp-ui-mode)
  :config
  (progn
    (general-setq lsp-ui-sideline-enable nil
                  lsp-ui-doc-enable nil)

    (define-key lsp-ui-mode-map (kbd "C-c C-c") #'lsp-goto-type-definition)
    (define-key lsp-ui-mode-map (kbd "C-c i") #'lsp-goto-implementation)
    (define-key lsp-ui-mode-map [remap evil-lookup] #'lsp-describe-thing-at-point)
    (define-key lsp-ui-mode-map [remap xref-find-definitions] #'lsp-ui-peek-find-definitions)
    (define-key lsp-ui-mode-map [remap xref-find-references] #'lsp-ui-peek-find-references)))

(provide 'config-lsp)

;;; config-lsp.el ends here
