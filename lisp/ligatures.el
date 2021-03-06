;;; ligatures.el --- Use Hasklig to provide ligatures.  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Chris Barrett

;; Author: Chris Barrett <chris+emacs@walrus.cool>
;; Package-Requires: ((dash "2.12.0") (memoize "1.1") (emacs "24"))

;; Version: 0.1.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'dash)
(require 'memoize)

(defconst ligatures-list
  '("&&" "***" "*>" "\\\\" "||" "|>" "::"
    "==" "===" "==>" "=>" "=<<" "!!" ">>"
    ">>=" ">>>" ">>-" ">-" "->" "-<" "-<<"
    "<*" "<*>" "<|" "<|>" "<$>" "<>" "<-"
    "<<" "<<<" "<+>" ".." "..." "++" "+++"
    "/=" ":::" ">=>" "->>" "<=>" "<=<" "<->")
  "A list of ligatures to enable.

See https://github.com/i-tu/Hasklig/blob/master/GlyphOrderAndAliasDB#L1588")

(defmemoize ligatures-alist ()
  (ligatures--fix-symbol-bounds (ligatures--ligature-list ligatures-list #Xe100)))

(defun ligatures--fix-symbol-bounds (alist)
  (-map (-lambda ((symbol . codepoint))
          (cons symbol
                (cond ((equal 2 (length symbol))
                       `(?\s (Br . Bl) ?\s (Br . Br) ,codepoint))
                      ((equal 3 (length symbol))
                       `(?\s (Br . Bl) ?\s (Br . Bc) ?\s (Br . Br) ,codepoint))
                      (t
                       (string ?\t codepoint)))))
        alist))

(defun ligatures--ligature-list (ligatures codepoint-start)
  (let ((codepoints (-iterate '1+ codepoint-start (length ligatures))))
    (-zip-pair ligatures codepoints)))

;;;###autoload
(defun ligatures-init ()
  (when (equal 'Hasklig (ignore-errors (font-get (face-attribute 'default :font) :family)))
    (setq prettify-symbols-alist (-union prettify-symbols-alist (ligatures-alist)))
    ;; Refresh symbol rendering.
    (prettify-symbols-mode -1)
    (prettify-symbols-mode +1)))

(provide 'ligatures)

;;; ligatures.el ends here
