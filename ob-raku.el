;;; ob-raku.el --- org-babel functions for Raku evaluation

;; Copyright (C) Tim Van den Langenbergh

;; Author: Tim Van den Langenbergh <tmt_vdl@gmx.com>
;; Keywords: literate programming, reproducible research, Raku
;; Homepage: https://github.com/tmtvl/ob-raku
;; Version: 0.01

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Bindings for org-babel support for Raku (née Perl6).

;;; Requirements:

;; Requires a working Raku interpreter to be installed.
;; (Optionally) requires Perl6 mode to be installed.

;;; Code:
(require 'comint)
(require 'ob)
(require 'ob-comint)
(require 'ob-eval)
(require 'ob-ref)
(eval-when-compile (require 'cl))

;; define a file extension for this language
(add-to-list 'org-babel-tangle-lang-exts '("raku" . "raku"))

(defvar org-babel-default-header-args:raku '())

(defvar org-babel-raku-command "raku" "Name of the Raku executable command.")

(defun org-babel-execute:raku (body params)
  "Evaluate the BODY through Raku passing through the PARAMS."
  (let* ((processed-params (org-babel-process-params params))
	 (session (org-babel-raku-initiate-session (cdr (assoc :session params))))
	 (result-type (cdr (assoc :result-type params)))
	 (full-body (org-babel-expand-body:generic
		     body params (org-babel-variable-assignments:raku params))))
    (org-babel-reassemble-table
     (org-babel-raku-evaluate session full-body result-type)
     (org-babel-pick-name
      (cdr (assoc :colname-names params)) (cdr (assoc :colnames params)))
     (org-babel-pick-name
      (cdr (assoc :rowname-names params)) (cdr (assoc :rownames params))))))

(defun org-babel-prep-session:raku (session params)
  "Prepare SESSION according to the header arguments in PARAMS."
  (let* ((session (org-babel-raku-initiate-session session))
	 (var-lines (org-babel-variable-assignments:raku params)))
    (org-babel-comint-in-buffer session
      (mapc (lambda (var)
	      (end-of-line 1) (insert var) (comint-send-input)
	      (org-babel-comint-wait-for-output session)) var-lines))
    session))

(defun org-babel-load-session:raku (session body params)
  "Load BODY into SESSION with PARAMS."
  (save-window-excursion
    (let ((buffer (org-babel-prep-session:raku session params)))
      (with-current-buffer buffer
	(goto-char (process-mark (get-buffer-process (current-buffer))))
	(insert (org-babel-chomp body)))
      buffer)))

(defun org-babel-variable-assignments:raku (params)
  "Return list of Raku statements assigning the block's variables with PARAMS."
  (mapcar
   (lambda (pair)
     (format
      "%s%s=%s;"
      (if (listp (cdr pair))
	  "@"
	"$")
      (car pair)
      (org-babel-raku-var-to-raku (cdr pair))))
   (mapcar
    #'cdr
    (delq nil
	  (mapcar
	   (lambda (p) (when (eq (car p) :var) p))
	   params)))))

(defun org-babel-raku-var-to-raku (var)
  "Convert an elisp value to a Raku variable.
The elisp value, VAR, is converted to a string of Raku source code
specifying a var of the same value."
  (if (listp var)
      (concat "(" (mapconcat #'org-babel-raku-var-to-raku var ", ") ")")
    (format "%s" var)))

(defun org-babel-raku-initiate-session (&optional session)
  "Return SESSION with a current inferior-process-buffer.
Initializes SESSION if it hasn't already."
  (unless (string= session "none")
    (let* ((session (or session "*raku*"))
	   (buffer (get-buffer-create session)))
      (unless (comint-check-proc buffer)
	(make-comint-in-buffer session buffer org-babel-raku-command))
      buffer)))

(defvar org-babel-raku-eoe-indicator "'org_babel_raku_eoe'"
  "A string to indicate that evaluation has completed.")

(defvar org-babel-raku-wrapper "sub _MAIN () {
%s
}
\"%s\".IO.spurt(_MAIN().perl ~ \"\n\");"
  "Wrapper for simply showing the output of the Raku code.")

(defun org-babel-raku-evaluate (session body &optional result-type)
  "Evaluate BODY as Raku code.
If a SESSION isn't available it will be evaluated externally."
  (if session
      (org-babel-raku-evaluate-session session body result-type)
    (org-babel-raku-evaluate-external body result-type)))

(defun org-babel-raku-evaluate-external (body &optional result-type)
  "Evaluate Raku BODY in external process.
If RESULT-TYPE equals 'output then return standard output as a string.
If RESULT-TYPE equals 'value then return the value of the last
statement in BODY, as elisp."
  (case result-type
    (output
     (message "Output")
     (org-babel-eval org-babel-raku-command body))
    (value
     (message "Value")
     (let ((tmp-file (org-babel-temp-file "raku-")))
		 (org-babel-eval
		  org-babel-raku-command
		  (format org-babel-raku-wrapper body
			  (org-babel-process-file-name tmp-file 'noquote)))
		 (org-babel-eval-read-file tmp-file)))))

(defun org-babel-raku-evaluate-session (session body &optional result-type)
  "Pass BODY to the Raku process in SESSION.
If RESULT-TYPE equals 'output then return standard output as a string.
If RESULT-TYPE equals 'value then return the value of the last
statement in BODY, as elisp."
  ;; TODO: Support value returns.
  (error "Not yet implemented"))

(provide 'ob-raku)
;;; ob-raku.el ends here
