;;; capture-arabic.el --- Supporting functions for org-capture  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'anki)
(require 'dash)
(require 'pretty-hydra)
(require 'subr-x)



(defvar capture-arabic--arabic-input-history nil)

(defvar capture-arabic--english-input-history nil)

(defvar capture-arabic--tags-input-history nil)

(defun capture-arabic--read-en (prompt &optional default)
  (let ((prompt-str (concat "‎[en] "
                            (if default
                                (concat prompt " [default: " default "]")
                              prompt)
                            ": ")))
    (read-string prompt-str nil 'capture-arabic--english-input-history default)))

(defun capture-arabic--read-tags ()
  (let* ((default (car capture-arabic--tags-input-history))
         (prompt-str (concat "Tags"
                             (if default (concat " [default: " default "]") "")
                             ": " ))
         (input (read-string prompt-str nil 'capture-arabic--tags-input-history default)))
    (-uniq (s-split (rx (+ (any space ",")))
                    input
                    t))))

(defun capture-arabic--read-ar (prompt &optional default)
  (let ((setup (lambda () (set-input-method "walrus-arabic")))
        (prompt-str (concat "‎[العربية] "
                            (if default
                                (concat prompt " [default: " default "]")
                              prompt)
                            ": ")))
    (add-hook 'minibuffer-setup-hook setup)
    (unwind-protect
        (read-string prompt-str nil 'capture-arabic--arabic-input-history default t)
      (remove-hook 'minibuffer-setup-hook setup))))

(defun capture-arabic--read-gender ()
  (char-to-string
   (read-char-choice "Choose gender: \n    [m]ale\n    [f]emale"
                     (list ?m ?f))))



(defun capture-arabic--pluralise-en (word-or-words)
  (cl-labels ((pluralise
               (word)
               (cond
                ((string-suffix-p "us" word)
                 (concat (string-remove-suffix "us" word) "i"))
                ((string-suffix-p "on" word)
                 (concat (string-remove-suffix "on" word) "a"))
                ((string-match-p (rx (not (any "yaeiou")) "y" eos)
                                 word)
                 (concat (string-remove-suffix "y" word) "ies"))
                ((or (string-suffix-p "s" word)
                     (string-suffix-p "o" word)
                     (string-suffix-p "sh" word)
                     (string-suffix-p "ch" word)
                     (string-suffix-p "is" word)
                     (string-suffix-p "x" word)
                     (string-suffix-p "z" word))
                 (concat word "es"))
                (t
                 (concat word "s")))))
    (let ((words (split-string word-or-words (rx ",")
                               t
                               (rx (+ space)))))
      (string-join (-map #'pluralise words) ", "))))

(defun capture-arabic--pluralise-ar (word)
  (cond
   ((string-suffix-p "ة" word)
    (concat (string-remove-suffix "ة" word) "ات"))))

(defun capture-arabic--remove-ar-vowels (str)
  (s-replace-regexp (rx (or "َ" "ِ" "ُ" "ْ"))
                    ""
                    str))

(defun capture-arabic-noun ()
  "Capture a noun to Anki."
  (interactive)
  (let* ((ar-sing (capture-arabic--read-ar "singular"))
         (ar-pl (capture-arabic--read-ar "plural" (capture-arabic--pluralise-ar ar-sing)))
         (ar-g (capture-arabic--read-gender))
         (en-sing (capture-arabic--read-en "singular"))
         (ar-s-pl (concat ar-sing "، " ar-pl))
         (tags (capture-arabic--read-tags))
         (note
          `((deckName . "Arabic")
            (modelName . "Arabic Noun")
            (tags . ,(seq-into tags 'vector))
            (fields . ,(-filter #'cdr `(("en" . ,en-sing)
                                        ("ar" . ,(capture-arabic--remove-ar-vowels ar-s-pl))
                                        ("ar_v" . ,ar-s-pl)
                                        ("ar_g" . ,ar-g)
                                        ;; Sound fields are left unpopulated.
                                        ("ar_audio" . "")))))))
    (anki-add-note note)))

(defun capture-arabic-phrase ()
  "Capture a phrase to Anki."
  (interactive)
  (let* ((ar (capture-arabic--read-ar "Arabic phrase"))
         (en (capture-arabic--read-en "English meaning"))
         (tags (capture-arabic--read-tags))
         (note
          `((deckName . "Arabic")
            (modelName . "Arabic Phrase")
            (tags . ,(seq-into tags 'vector))
            (fields . ,(-filter #'cdr `(("en" . ,en)
                                        ("ar" . ,(capture-arabic--remove-ar-vowels ar))
                                        ("ar_v" . ,ar)
                                        ;; Sound fields are left unpopulated.
                                        ("ar_audio" . "")))))))
    (anki-add-note note)))

(defun capture-arabic-read-verb-as-table-row ()
  (concat "|" (capture-arabic--read-en "verb")
          "|" (capture-arabic--read-ar "past")
          "|" (capture-arabic--read-ar "present")
          "|" (capture-arabic--read-ar "masdar")
          "|"))

(pretty-hydra-define capture-arabic (:hint nil :exit nil)
  ("Capture"
   (("n" capture-arabic-noun "Noun...")
    ("p" capture-arabic-phrase "Phrase...")))
  :docstring-prefix "‎العربية\n")

(provide 'capture-arabic)

;;; capture-arabic.el ends here
