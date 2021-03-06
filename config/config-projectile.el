;;; config-projectile.el --- Configuration for projectile.  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(eval-when-compile
  (require 'use-package)
  (require 'subr-x))

(require 'dash-functional)
(require 'paths)
(require 'projectile-funcs)

(autoload 'js-test-commands-locate-impl-file "js-test-commands")
(autoload 'js-test-commands-locate-test-file "js-test-commands")



;; projectile-funcs contains functions used by the configuration for projectile.

(use-package projectile-funcs
  :defines (projectile-funcs-ignored-base-dirs)
  :config
  (setq projectile-funcs-ignored-base-dirs
        '("/nix/store/"
          "~/.nvm/"
          "~/.ghc/"
          "~/.stack/"
          "~/.emacs.d/straight/"
          "~/.rustup/"
          "~/tmp/")))

;; Projectile provides commands for working with projects.

(use-package projectile
  :straight t
  :commands (projectile-mode)
  :preface
  (progn
    (autoload 'projectile-files-from-cmd "projectile")
    (autoload 'projectile-find-matching-file "projectile")
    (autoload 'projectile-find-matching-test "projectile")
    (autoload 'projectile-project-root "projectile")
    (autoload 'projectile-register-project-type "projectile")
    (autoload 'projectile-test-file-p "projectile")
    (autoload 'projectile-test-project "projectile")
    (autoload 'projectile-unixy-system-p "projectile")

    (defun config-projectile--find-files-with-string-using-rg (fn string directory)
      (if (and (projectile-unixy-system-p) (executable-find "rg"))
          (let* ((search-term (shell-quote-argument string))
                 (cmd (concat "rg --fixed-strings --color=never --no-heading --files-with-matches -- " search-term)))

            (projectile-files-from-cmd cmd directory))
        (funcall fn string directory)))

    (defun config-projectile--file-has-test-suffix-p (file)
      (string-match-p (rx ".test." (or "js" "ts") eos) file))

    (defun config-projectile--file-is-child-of-test-dir-p (file)
      (seq-contains (f-split file) "test"))

    (defun config-projectile--test-file-p (&optional has-test-prefix-or-suffix)
      (or has-test-prefix-or-suffix
          (config-projectile--file-has-test-suffix-p (buffer-name))
          (when-let* ((file (buffer-file-name)))
            (config-projectile--file-is-child-of-test-dir-p file))))

    (defun config-projectile--substitute-test-with-impl (&optional existing)
      (or existing
          (when-let* ((file (buffer-file-name)))
            (js-test-commands-locate-impl-file file))))

    (defun config-projectile--substitute-impl-with-test (&optional existing)
      (or existing
          (when-let* ((file (buffer-file-name)))
            (js-test-commands-locate-test-file file))))

    (defun config-projectile-test-project (arg)
      (interactive "P")
      (let ((compilation-buffer-name-function (-const "*projectile-test*")))
        (projectile-test-project arg))))

  :init
  (projectile-mode +1)

  :config
  (progn
    (advice-add 'projectile-load-known-projects :override #'projectile-funcs-refresh-projects)
    (advice-add 'projectile-save-known-projects :override #'ignore)

    (setq projectile-project-search-path paths-project-directories)
    (setq projectile-completion-system 'ivy)
    (setq projectile-switch-project-action #'dired)
    (setq projectile-enable-caching t)
    (setq projectile-create-missing-test-files t)

    (setq projectile-globally-ignored-files '("TAGS" ".DS_Store" "package-lock.json"))
    (setq projectile-globally-ignored-file-suffixes '("meta" "jsbundle" "gz" "zip" "tar" "elc"))

    (setq projectile-ignored-project-function #'projectile-funcs-ignored-subdir-p)

    (setq projectile-globally-ignored-directories
          '(
            "coverage"
            ".bzr"
            ".ensime_cache"
            ".eunit"
            ".fslckout"
            ".g8"
            ".git"
            ".hg"
            ".idea"
            ".stack-work"
            ".svn"
            "dist"
            "jars"
            "node_modules"
            "flow-typed/npm"
            "vendor"
            "straight/repos"
            "target"
            ))


    ;; Teach projectile how to resolve npm srcs and tests.
    (advice-add #'projectile-test-file-p :filter-return #'config-projectile--test-file-p)
    (advice-add #'projectile-find-matching-file :filter-return #'config-projectile--substitute-test-with-impl)
    (advice-add #'projectile-find-matching-test :filter-return #'config-projectile--substitute-impl-with-test)

    ;; Teach projectile to prefer rg for finding files containing strings
    (advice-add 'projectile-files-with-string :around #'config-projectile--find-files-with-string-using-rg)))

;; counsel-projectile provides ivy wrappers for projectile commands.

(use-package counsel-projectile
  :straight t
  :defer t
  :commands (counsel-projectile-mode)
  :config
  (progn
    (setq counsel-projectile-switch-project-action #'dired)
    (counsel-projectile-mode)))

(provide 'config-projectile)

;;; config-projectile.el ends here
