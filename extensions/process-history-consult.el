;;; process-history-consult.el --- Process history consult integration -*- lexical-binding: t -*-

;; Copyright (C) 2023  Free Software Foundation, Inc.

;; Author: Daniel Pettersson
;; Maintainer: Daniel Pettersson <daniel@dpettersson.net>
;; Created: 2023
;; License: GPL-3.0-or-later
;; Version: 0.0.1
;; Homepage: https://github.com/svaante/process-history
;; Package-Requires: ((emacs "29.1") (consult))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; To enable usage of consult backed completing-read interface, set
;; the default completing read function for process-history.

;; (setopt process-history-completing-read-fn
;;   'process-history-consult-completing-read)

;;; Code:

(require 'process-history)
(require 'consult)

(defun process-history-consult-completing-read (prompt &optional predicate)
  "Read a string in the minibuffer, with completion.
PROMPT is a string to prompt with; normally it ends in a colon and a
space.
PREDICATE is an optional function taking command string and
`process-history--item'.
Completes from collection based on `process-history'."
  (let* ((alist
          (seq-filter (or predicate 'identity)
                      (process-history--collection)))
         (base-source
          `(:annotate ,(process-history--make-annotation-function alist)
            :category process-history))
         (sources
          `((:name "Active"
             :narrow ?a
             :items ,(mapcan (pcase-lambda (`(,str . ,item))
                               (unless (process-history--item-exit-code item)
                                 (list str)))
                             alist)
             ,@base-source)
            (:name "Exited"
             :narrow ?f
             :items ,(mapcan (pcase-lambda (`(,str . ,item))
                                     (when (process-history--item-exit-code item)
                                       (list str)))
                                   alist)
             ,@base-source)
            (:name "Project"
             :narrow ?p
             :hidden t
             :items
             ,(when-let* ((root (consult--project-root))
                          (root (abbreviate-file-name root)))
                (mapcan (pcase-lambda (`(,str . ,item))
                          (when (equal root (process-history--item-directory item))
                            (list str)))
                        alist))
             ,@base-source)
            (:name ,(format "Directory (%s)" default-directory)
             :narrow ?d
             :hidden t
             :items
             ,(mapcan (pcase-lambda (`(,str . ,item))
                        (when (equal default-directory (process-history--item-directory item))
                          (list str)))
                      alist)
             ,@base-source)))
         (match
          (car (consult--multi sources
                               :prompt prompt
                               :require-match t
                               :sort nil))))
      (alist-get match alist nil nil 'equal)))

(provide 'process-history-consult)
;;; process-history-consult.el ends here
