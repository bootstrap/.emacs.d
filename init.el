;;; init.el --- Startup file for Emacs.  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(when (version< emacs-version "26")
  (error "This version of Emacs is not supported"))

(setq gc-cons-threshold (* 800 1024))

(defconst emacs-start-time (current-time))

(unless noninteractive
  (message "Loading %s..." load-file-name))

(setenv "INSIDE_EMACS" "true")

;; Make sure package.el doesn't get a chance to load anything.

(setq package-enable-at-startup nil)


;; Bootstrap straight.el package manager.

(eval-and-compile
  (defvar bootstrap-version 5)
  (defvar bootstrap-file (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory)))

(unless (file-exists-p bootstrap-file)
  (with-current-buffer
      (url-retrieve-synchronously
       "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
       'silent 'inhibit-cookies)
    (goto-char (point-max))
    (eval-print-last-sexp)))

(load bootstrap-file nil 'nomessage)

(with-no-warnings
  (setq straight-cache-autoloads t)
  (setq straight-check-for-modifications '(watch-files)))

(require 'straight bootstrap-file t)


;; Install some basic packages

(straight-use-package 'dash)
(straight-use-package 'dash-functional)
(straight-use-package 'f)
(straight-use-package 's)
(straight-use-package 'noflet)
(straight-use-package 'memoize)
(straight-use-package 'general)
(straight-use-package 'el-patch)

(with-no-warnings
  (setq use-package-verbose t))

(straight-use-package 'bind-map)
(straight-use-package 'use-package)

(eval-when-compile
  (require 'use-package))


;; Load features.

(require 'paths (expand-file-name "paths.el" user-emacs-directory))
(paths-initialise)
(add-to-list 'custom-theme-load-path paths-themes-directory)

;; Ensure org-version hack is activated.
(require 'org-version (expand-file-name "org-version.el" paths-hacks-directory))

;; no-littering overrides many common paths to keep the .emacs.d directory
;; clean.
;;
;; Load it here since we want to refer to path vars, and need to make sure it's
;; loaded very early in the startup process.

(use-package no-littering
  :straight t
  :demand t
  :init
  (progn
    (setq no-littering-etc-directory paths-etc-directory)
    (setq no-littering-var-directory paths-cache-directory))
  :config
  (progn
    (setq auto-save-file-name-transforms
          `((".*" ,(f-join paths-cache-directory "auto-save") t)))

    (eval-when-compile
      (require 'recentf))

    (with-eval-after-load 'recentf
      (add-to-list 'recentf-exclude no-littering-etc-directory)
      (add-to-list 'recentf-exclude no-littering-var-directory))))

;; Load theme aggressively, or Emacs will look ugly during the startup sequence.
(use-package config-themes
  :commands (config-themes-set-for-time-of-day)
  :demand t
  :config
  (add-hook 'before-make-frame-hook #'config-themes-set-for-time-of-day))

(use-package config-basic-settings)

(use-package config-darwin
  :if (equal system-type 'darwin))

(use-package config-nixos
  :if (and (equal system-type 'gnu/linux)
           (string-match-p "nixos" (f-read "/proc/version"))))

(use-package config-modeline)
(use-package config-editing)
(use-package config-hydras)
(use-package config-evil)
(use-package config-ivy)
(use-package config-search)
(use-package config-projectile)
(use-package config-langs)
(use-package config-elisp)
(use-package config-smartparens)
(use-package config-git)
(use-package config-company)
(use-package config-yasnippet)
(use-package config-flycheck)
(use-package config-mu4e)
(use-package config-org)
(use-package config-ledger)
(use-package config-rust)
(use-package config-dired)
(use-package config-ibuffer)
(use-package config-web-mode)
(use-package config-markdown)
(use-package config-restclient)
(use-package config-haskell)
(use-package config-latex)
(use-package config-python)
(use-package config-nix)
(use-package config-etags)
(use-package config-treemacs)
(use-package config-eshell)
(use-package config-docker)
(use-package config-lsp)
(use-package config-java)
(use-package config-csharp)

(use-package personal-config
  :load-path "~/Sync/personal-config")

(when (file-exists-p paths-hostfile)
  (load-file paths-hostfile))

(unless user-full-name (warn "`user-full-name' not set"))
(unless user-mail-address (warn "`user-mail-address' not set"))


;;; Post init setup.

(unless (file-directory-p org-directory)
  (when (y-or-n-p (format "`org-directory' does not exist. Create at %s? " org-directory))
    (mkdir org-directory)))

;;; Print overall startup time.

(unless noninteractive
  (let ((elapsed (float-time (time-subtract (current-time) emacs-start-time))))
    (message "Loading %s...done (%.3fs)" load-file-name elapsed))

  (add-hook 'after-init-hook
            `(lambda ()
               (let ((elapsed (float-time (time-subtract (current-time)
                                                         emacs-start-time))))
                 (message "Loading %s...done (%.3fs) [after-init]"
                          ,load-file-name elapsed)))
            t))


(provide 'init)

;;; init.el ends here
