;;; skewer-repl.el --- create a REPL in a visiting browser

;; This is free and unencumbered software released into the public domain.

;; Author: Christopher Wellons <mosquitopsu@gmail.com>
;; URL: https://github.com/skeeto/skewer-mode
;; Version: 1.0

;;; Commentary:

;; This is largely based on of IELM's code. Run `skewer-repl' to
;; switch to the REPL buffer and evaluate code.

;;; Code:

(require 'skewer-mode)

(defvar skewer-repl-prompt "js> "
  "Prompt string for JavaScript REPL.")

(defun skewer-repl-process ()
  "Return the process for the skewer REPL."
  (get-buffer-process (current-buffer)))

(define-derived-mode skewer-repl-mode comint-mode "js-REPL"
  "Provide a REPL into the visiting browser."
  :syntax-table emacs-lisp-mode-syntax-table
  (setq comint-prompt-regexp (concat "^" (regexp-quote skewer-repl-prompt)))
  (setq comint-input-sender 'skewer-input-sender)
  (add-to-list 'skewer-callbacks 'skewer-post-repl)
  (unless (comint-check-proc (current-buffer))
    (start-process "ielm" (current-buffer) "hexl")
    (set-process-query-on-exit-flag (skewer-repl-process) nil)
    (end-of-buffer)
    (set (make-local-variable 'comint-inhibit-carriage-motion) t)
    (comint-output-filter (skewer-repl-process) skewer-repl-prompt)
    (set-process-filter (skewer-repl-process) 'comint-output-filter)))

(defun skewer-input-sender (proc input)
  "REPL comint handler."
  (skewer-eval input 'skewer-post-repl))

(defun skewer-post-repl (result)
  "Callback for reporting results in the REPL."
  (let ((buffer (get-buffer "*skewer-repl*"))
        (output (cdr (assoc 'value result))))
    (when buffer
      (with-current-buffer buffer
        (comint-output-filter (skewer-repl-process)
                              (concat output "\n" skewer-repl-prompt))))))

(defun skewer-repl ()
  "Start a JavaScript REPL to be evaluated in the visiting browser."
  (interactive)
  (when (not (get-buffer "*skewer-repl*"))
    (with-current-buffer (get-buffer-create "*skewer-repl*")
      (skewer-repl-mode)))
  (switch-to-buffer (get-buffer "*skewer-repl*")))

(provide 'skewer-repl)

;;; skewer-repl.el ends here
