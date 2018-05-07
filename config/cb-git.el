;;; cb-git.el --- Configuration for git.  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Chris Barrett

;; Author: Chris Barrett <chris+emacs@walrus.cool>

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'use-package))

(require 'cb-emacs)
(require 'spacemacs-keys)
(require 'evil-transient-state)

(autoload 'evil-define-key "evil-core")

(add-to-list 'auto-mode-alist '("\\.gitignore\\'" . conf-unix-mode))

(use-package git-subtree
  :commands (git-subtree-add git-subtree-update git-subtree-push)
  :init
  (put 'git-subtree-rev-alist 'safe-local-variable #'listp))

(use-package magit
  :defer t
  :commands (magit-status magit-blame magit-branch-and-checkout)
  :functions (magit-display-buffer-fullframe-status-v1)
  :preface
  (progn
    (autoload 'magit-diff-dwim "magit-diff")
    (autoload 'magit-file-relative-name "magit-git")
    (autoload 'magit-find-file "magit-files")
    (autoload 'magit-find-file-other-window "magit-files")
    (autoload 'magit-popup-import-file-args "magit-popup")

    (defun cb-git-find-file (&optional arg)
      (interactive "P")
      (if arg
          (call-interactively #'magit-find-file)
        (call-interactively #'magit-find-file-other-window)))

    (defun cb-git-diff-buffer-file (&optional arg)
      (interactive "P")
      (let* ((file (magit-file-relative-name))
             (magit-diff-arguments
              (when file
                (magit-popup-import-file-args (default-value 'magit-diff-arguments) (list file)))))
        (cond
         (arg
          (call-interactively #'magit-diff-buffer-file-popup))
         (file
          (call-interactively #'magit-diff))
         (t
          (user-error "Buffer isn't visiting a file")))))

    (evil-transient-state-define git-blame
      :title "Git Blame Transient State"
      :doc "
Press [_b_] again to blame further in the history, [_q_] to go up or quit."
      :on-enter (unless (bound-and-true-p magit-blame-mode)
                  (call-interactively 'magit-blame))
      :foreign-keys run
      :bindings
      ("b" magit-blame)
      ("q" nil :exit (progn (when (bound-and-true-p magit-blame-mode)
                              (magit-blame-quit))
                            (not (bound-and-true-p magit-blame-mode))))))
  :init
  (spacemacs-keys-set-leader-keys
    "gs" #'magit-status
    "gl" #'magit-log-buffer-file
    "gd" #'cb-git-diff-buffer-file
    "gf" #'cb-git-find-file
    "gt" #'git-time-machine-transient-state/body
    "gb" #'git-blame-transient-state/body)
  :config
  (progn
    (evil-define-key 'normal magit-refs-mode-map (kbd ".") #'magit-branch-and-checkout)
    (setq magit-display-buffer-function #'magit-display-buffer-fullframe-status-v1)
    (setq magit-log-section-commit-count 0)))

(use-package magithub
  :after magit
  :config
  (progn
    (require 'magithub-completion)
    (magithub-feature-autoinject t)
    (setq magithub-clone-default-directory "~/Projects")))

(use-package git-commit-jira-prefix
  :after git-commit
  :commands git-commit-jira-prefix-init
  :config (git-commit-jira-prefix-init))

(use-package evil-magit
  :after magit
  :config
  (evil-magit-init))

(use-package git-auto-commit-mode
  :commands (git-auto-commit-mode)
  :init
  (add-to-list 'safe-local-variable-values '(gac-automatically-push-p . t))
  :preface
  (progn
    (require 'deferred)

    (defun cb-git--maybe-commit-and-push ()
      (let ((file (convert-standard-filename (file-name-nondirectory (buffer-file-name)))))
        (deferred:try
          (deferred:$
            (deferred:process "git" "add" (shell-quote-argument file))
            (deferred:processc it "git" "commit" "-m" (shell-quote-argument (gac--commit-msg (buffer-file-name)))))
          :finally #'gac-push))))

  :config
  (defalias 'gac-after-save-func #'cb-git--maybe-commit-and-push))

(use-package git-timemachine
  :defer t
  :commands
  (git-timemachine
   git-timemachine-show-current-revision
   git-timemachine-show-nth-revision
   git-timemachine-show-previous-revision
   git-timemachine-show-next-revision
   git-timemachine-show-previous-revision
   git-timemachine-kill-revision
   git-timemachine-quit)
  :preface
  (evil-transient-state-define git-time-machine
    :title "Git Timemachine Transient State"
    :doc "
[_p_/_N_] previous [_n_] next [_c_] current [_g_] goto nth rev [_Y_] copy hash [_q_] quit"
    :on-enter (unless (bound-and-true-p git-timemachine-mode)
                (call-interactively 'git-timemachine))
    :on-exit (when (bound-and-true-p git-timemachine-mode)
               (git-timemachine-quit))
    :foreign-keys run
    :bindings
    ("c" git-timemachine-show-current-revision)
    ("g" git-timemachine-show-nth-revision)
    ("p" git-timemachine-show-previous-revision)
    ("n" git-timemachine-show-next-revision)
    ("N" git-timemachine-show-previous-revision)
    ("Y" git-timemachine-kill-revision)
    ("q" nil :exit t)))

(use-package diff-hl
  :after magit
  :commands (diff-hl-magit-post-refresh
             global-diff-hl-mode
             diff-hl-next-hunk
             diff-hl-previous-hunk
             diff-hl-revert-hunk
             diff-hl-goto-hunk)
  :preface
  (progn
    (defun cb-git--diff-hl-mode-on ()
      (diff-hl-mode -1))

    (defun cb-git--diff-hl-mode-off ()
      (diff-hl-mode +1)))

  :init
  (progn

    (evil-transient-state-define git-hunks
      :title "Git Hunk Transient State"
      :doc "
[_p_/_N_] previous [_n_] next [_g_] goto [_x_] revert [_q_] quit"
      :foreign-keys run
      :bindings
      ("n" diff-hl-next-hunk)
      ("N" diff-hl-previous-hunk)
      ("p" diff-hl-previous-hunk)
      ("g" diff-hl-goto-hunk)
      ("x" diff-hl-revert-hunk)
      ("q" nil :exit t))

    (spacemacs-keys-set-leader-keys "gh" 'git-hunks-transient-state/body))

  :config
  (progn
    ;; Diff-hl interferes with iedit. Disable diff-hl temporarily while iedit is
    ;; enabled.
    (add-hook 'iedit-mode-hook #'cb-git--diff-hl-mode-on)
    (add-hook 'iedit-mode-end-hook #'cb-git--diff-hl-mode-off)

    (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
    (global-diff-hl-mode)))


(use-package magit-gpg
  :after magit
  :functions (magit-gpg-insert-revision-gpg)
  :config
  (magit-add-section-hook 'magit-revision-sections-hook
                          #'magit-gpg-insert-revision-gpg
                          #'magit-insert-revision-headers
                          t))


(provide 'cb-git)

;;; cb-git.el ends here
